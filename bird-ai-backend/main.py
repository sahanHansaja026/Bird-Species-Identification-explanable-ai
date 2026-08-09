import os
import io
import base64

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn
import numpy as np
import librosa
import tensorflow as tf
import cv2
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend for thread safety
import matplotlib.pyplot as plt
from tensorflow.keras.models import load_model
from payment import router as payment_router

# =========================
# FASTAPI INIT
# =========================

app = FastAPI(title="Bird Sound Classification API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="."), name="static")
app.include_router(payment_router)

# =========================
# LOAD MODEL WITH SHAPE FIX
# =========================

MODEL_PATH = "bird_classifier.keras"

class PatchedInputLayer(tf.keras.layers.InputLayer):
    def __init__(self, *args, **kwargs):
        if 'batch_shape' in kwargs:
            kwargs['shape'] = kwargs['batch_shape'][1:]
        elif 'shape' not in kwargs:
            kwargs['shape'] = (128, 128, 1)
        super().__init__(*args, **kwargs)

model = load_model(
    MODEL_PATH, 
    custom_objects={"InputLayer": PatchedInputLayer}
)

# =========================
# LABELS
# =========================

labels = [
    "greenbilled coucal",
    "crow",
    "peacock",
    "rooster"
]

index_to_label = {i: label for i, label in enumerate(labels)}

# =========================
# GET LAST CONV LAYER NAME
# =========================

def get_last_conv_layer_name(model):
    for layer in reversed(model.layers):
        if isinstance(layer, tf.keras.layers.Conv2D):
            return layer.name
    raise ValueError("No Conv2D layer found in model.")

last_conv_layer_name = get_last_conv_layer_name(model)

# =========================
# AUDIO CLEANING & FEATURES
# =========================

def clean_audio(audio, sr):
    audio, _ = librosa.effects.trim(audio)
    if len(audio) == 0:
        raise ValueError("Audio file is empty or entirely silence after trimming.")
    audio = librosa.util.normalize(audio)
    return audio

def extract_features(audio, sr, max_len=128):
    mel = librosa.feature.melspectrogram(y=audio, sr=sr)
    mel_db = librosa.power_to_db(mel, ref=np.max)

    if mel_db.shape[1] < max_len:
        pad_width = max_len - mel_db.shape[1]
        mel_db = np.pad(mel_db, ((0, 0), (0, pad_width)))
    else:
        mel_db = mel_db[:, :max_len]

    return mel_db

# =========================
# GRAD-CAM
# =========================

def make_gradcam_heatmap(img_array, model, last_conv_layer_name):
    img_tensor = tf.cast(img_array, dtype=tf.float32)

    conv_layer_idx = next(
        i for i, layer in enumerate(model.layers) if layer.name == last_conv_layer_name
    )
    
    features_layers = model.layers[:conv_layer_idx + 1]
    classifier_layers = model.layers[conv_layer_idx + 1:]

    with tf.GradientTape() as tape:
        conv_outputs = img_tensor
        for layer in features_layers:
            conv_outputs = layer(conv_outputs, training=False)
            
        tape.watch(conv_outputs)
        
        predictions = conv_outputs
        for layer in classifier_layers:
            predictions = layer(predictions, training=False)
            
        pred_index = tf.argmax(predictions[0])
        class_channel = predictions[:, pred_index]

    grads = tape.gradient(class_channel, conv_outputs)
    pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
    conv_outputs = conv_outputs[0]
    heatmap = tf.reduce_sum(pooled_grads * conv_outputs, axis=-1)

    heatmap = tf.maximum(heatmap, 0)
    heatmap = heatmap / (tf.reduce_max(heatmap) + 1e-8)

    return heatmap.numpy()

# =========================
# GENERATE GRADCAM BASE64 (IN-MEMORY)
# =========================

def generate_gradcam_base64(mel_image, heatmap):
    heatmap_resized = cv2.resize(heatmap, (mel_image.shape[1], mel_image.shape[0]))
    
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.imshow(mel_image, cmap="viridis", aspect="auto")
    ax.imshow(heatmap_resized, cmap="jet", alpha=0.4, aspect="auto")
    ax.axis("off")
    ax.set_title("Grad-CAM Explainable AI (Bird Call Analysis)")

    buf = io.BytesIO()
    plt.savefig(buf, format="png", bbox_inches="tight", dpi=100)
    plt.close(fig)
    buf.seek(0)

    # Clean up whitespace and line breaks from base64 encoding
    base64_encoded = base64.b64encode(buf.read()).decode("utf-8")
    clean_base64 = base64_encoded.replace("\n", "").replace("\r", "").strip()

    return f"data:image/png;base64,{clean_base64}"

# =========================
# PREDICT ROUTE
# =========================

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    safe_filename = file.filename.replace(" ", "_")
    temp_path = f"temp_{safe_filename}"

    with open(temp_path, "wb") as f:
        f.write(await file.read())

    try:
        audio, sr = librosa.load(temp_path, sr=22050)
        audio = clean_audio(audio, sr)
        features = extract_features(audio, sr)
        input_data = features[np.newaxis, ..., np.newaxis].astype(np.float32)

        # Base prediction
        prediction = model.predict(input_data)[0]
        predicted_index = int(np.argmax(prediction))
        predicted_label = index_to_label[predicted_index]
        confidence = float(prediction[predicted_index])

        probabilities = {
            index_to_label[i]: round(float(prediction[i]), 4)
            for i in range(len(labels))
        }

        # Heatmap Generation in Memory
        heatmap = make_gradcam_heatmap(input_data, model, last_conv_layer_name)
        gradcam_base64 = generate_gradcam_base64(features, heatmap)

        return {
            "predicted_bird": predicted_label,
            "confidence": round(confidence, 4),
            "all_probabilities": probabilities,
            "explainable_ai": {
                "gradcam_image": gradcam_base64,
                "grad_cam_layer_used": last_conv_layer_name,
                "description": f"The model detected frequencies specific to a {predicted_label}. Look at the warm-colored regions on the spectrogram image to see exactly which syllable patterns triggered the decision."
            }
        }

    except Exception as e:
        return {"error": str(e)}

    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)