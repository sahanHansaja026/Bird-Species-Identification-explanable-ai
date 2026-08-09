import { useState } from "react";
import { db, storage } from "./firebase";
import { collection, addDoc } from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";

function App() {
  // 🐦 Basic Info
  const [name, setName] = useState("");
  const [scientificName, setScientificName] = useState("");

  // 📝 Description
  const [shortDesc, setShortDesc] = useState("");
  const [longDesc, setLongDesc] = useState("");

  // 📋 Lists
  const [habitats, setHabitats] = useState<string[]>([]);
  const [diet, setDiet] = useState<string[]>([]);
  const [funFacts, setFunFacts] = useState<string[]>([]);

  // 🔤 Temp inputs
  const [habitatInput, setHabitatInput] = useState("");
  const [dietInput, setDietInput] = useState("");
  const [factInput, setFactInput] = useState("");

  // 🖼️ Media
  const [images, setImages] = useState<File[]>([]);
  const [mainImageIndex, setMainImageIndex] = useState(0);
  const [audio, setAudio] = useState<File | null>(null);

  const [loading, setLoading] = useState(false);

  // 📤 Upload helper
  const uploadFile = async (file: File, path: string) => {
    const fileRef = ref(storage, path);
    await uploadBytes(fileRef, file);
    return await getDownloadURL(fileRef);
  };

  // ➕ Add list items
  const addItem = (value: string, setFn: any, list: string[]) => {
    if (value.trim()) {
      setFn([...list, value.trim()]);
    }
  };

  // ❌ Remove item
  const removeItem = (index: number, list: string[], setFn: any) => {
    setFn(list.filter((_, i) => i !== index));
  };

  // 🚀 Submit
  const handleSubmit = async () => {
    if (!name || images.length === 0) {
      alert("Name and at least one image required ⚠️");
      return;
    }

    try {
      setLoading(true);

      const id = Date.now();

      // 📸 Upload images
      const imageUrls: string[] = [];
      for (let i = 0; i < images.length; i++) {
        const url = await uploadFile(
          images[i],
          `birds/${name}_${id}/image_${i}`
        );
        imageUrls.push(url);
      }

      // 🔊 Upload audio (optional)
      let soundUrl = "";
      if (audio) {
        soundUrl = await uploadFile(
          audio,
          `birds/${name}_${id}/sound`
        );
      }

      // 🧹 Clean data
      const birdData: any = {
        name,
        images: imageUrls,
        main_image: imageUrls[mainImageIndex],
        created_at: new Date(),
      };

      if (scientificName) birdData.scientific_name = scientificName;
      if (shortDesc) birdData.short_description = shortDesc;
      if (longDesc) birdData.long_description = longDesc;

      if (habitats.length) birdData.habitats = habitats;
      if (diet.length) birdData.diet = diet;
      if (funFacts.length) birdData.fun_facts = funFacts;

      if (soundUrl) birdData.sound_url = soundUrl;

      // 💾 Save
      await addDoc(collection(db, "birds"), birdData);

      alert("Bird saved successfully 🐦✅");

      // 🔄 Reset
      setName("");
      setScientificName("");
      setShortDesc("");
      setLongDesc("");
      setHabitats([]);
      setDiet([]);
      setFunFacts([]);
      setImages([]);
      setAudio(null);

    } catch (error) {
      console.error(error);
      alert("Error saving bird ❌");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <h1 className="title">🐦 Add Bird</h1>

      {/* BASIC INFO */}
      <div className="card">
        <h3>Basic Info</h3>

        <input
          className="input"
          placeholder="Bird Name *"
          value={name}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setName(e.target.value)
          }
        />

        <input
          className="input"
          placeholder="Scientific Name"
          value={scientificName}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setScientificName(e.target.value)
          }
        />
      </div>

      {/* DESCRIPTION */}
      <div className="card">
        <h3>Description</h3>

        <textarea
          className="textarea"
          placeholder="Short Description"
          value={shortDesc}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) =>
            setShortDesc(e.target.value)
          }
        />

        <textarea
          className="textarea"
          placeholder="Long Description"
          value={longDesc}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) =>
            setLongDesc(e.target.value)
          }
        />
      </div>

      {/* HABITATS */}
      <div className="card">
        <h3>Habitats</h3>

        <div className="row">
          <input
            className="input"
            value={habitatInput}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setHabitatInput(e.target.value)
            }
          />

          <button
            className="add-btn"
            onClick={() => {
              addItem(habitatInput, setHabitats, habitats);
              setHabitatInput("");
            }}
          >
            +
          </button>
        </div>

        <div className="chips">
          {habitats.map((h, i) => (
            <div key={i} className="chip">
              {h}
              <span onClick={() => removeItem(i, habitats, setHabitats)}>
                ✕
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* DIET */}
      <div className="card">
        <h3>Diet</h3>

        <div className="row">
          <input
            className="input"
            value={dietInput}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setDietInput(e.target.value)
            }
          />

          <button
            className="add-btn"
            onClick={() => {
              addItem(dietInput, setDiet, diet);
              setDietInput("");
            }}
          >
            +
          </button>
        </div>

        <div className="chips">
          {diet.map((d, i) => (
            <div key={i} className="chip">
              {d}
              <span onClick={() => removeItem(i, diet, setDiet)}>✕</span>
            </div>
          ))}
        </div>
      </div>

      {/* FUN FACTS */}
      <div className="card">
        <h3>Fun Facts</h3>

        <div className="row">
          <input
            className="input"
            value={factInput}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFactInput(e.target.value)
            }
          />

          <button
            className="add-btn"
            onClick={() => {
              addItem(factInput, setFunFacts, funFacts);
              setFactInput("");
            }}
          >
            +
          </button>
        </div>

        <div className="chips">
          {funFacts.map((f, i) => (
            <div key={i} className="chip">
              {f}
              <span onClick={() => removeItem(i, funFacts, setFunFacts)}>
                ✕
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* IMAGES */}
      <div className="card">
        <h3>Images *</h3>

        <input
          type="file"
          multiple
          accept="image/*"
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setImages(e.target.files ? Array.from(e.target.files) : [])
          }
        />

        <div className="image-grid">
          {images.map((img, i) => (
            <div
              key={i}
              className={`image-box ${i === mainImageIndex ? "active" : ""
                }`}
              onClick={() => setMainImageIndex(i)}
            >
              <img src={URL.createObjectURL(img)} alt="bird" />
            </div>
          ))}
        </div>
      </div>

      {/* AUDIO */}
      <div className="card">
        <h3>Bird Sound</h3>

        <input
          type="file"
          accept="audio/*"
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setAudio(e.target.files?.[0] || null)
          }
        />

        {audio && <p className="success">✅ {audio.name}</p>}
      </div>

      {/* SUBMIT */}
      <button className="submit" onClick={handleSubmit} disabled={loading}>
        {loading ? "Uploading..." : "Save Bird"}
      </button>
    </div>
  );
}

export default App;