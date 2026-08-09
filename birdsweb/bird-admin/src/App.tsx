import React, { useState, useEffect } from "react";
import { db, storage } from "./firebase";
import {
  collection,
  addDoc,
  getDocs,
  doc,
  updateDoc,
  deleteDoc,
  QueryDocumentSnapshot,
  type DocumentData,
} from "firebase/firestore";
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";

// ── TypeScript Interfaces ──────────────────────────────────
export interface Bird {
  id?: string;
  name: string;
  scientific_name?: string;
  short_description?: string;
  long_description?: string;
  habitats?: string[];
  diet?: string[];
  fun_facts?: string[];
  subscription: "free" | "premium";
  images: string[];
  main_image: string;
  sound_url?: string;
  created_at?: any;
}

function App() {
  // ── State Management ──────────────────────────────────────
  const [birds, setBirds] = useState<Bird[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [editingBirdId, setEditingBirdId] = useState<string | null>(null);

  // Form Fields
  const [name, setName] = useState("");
  const [scientificName, setScientificName] = useState("");
  const [shortDesc, setShortDesc] = useState("");
  const [longDesc, setLongDesc] = useState("");

  // Lists
  const [habitats, setHabitats] = useState<string[]>([]);
  const [diet, setDiet] = useState<string[]>([]);
  const [funFacts, setFunFacts] = useState<string[]>([]);

  // Dynamic Array Temp Inputs
  const [habitatInput, setHabitatInput] = useState("");
  const [dietInput, setDietInput] = useState("");
  const [factInput, setFactInput] = useState("");

  // Subscription & Media
  const [subscription, setSubscription] = useState<"free" | "premium">("free");
  const [existingImages, setExistingImages] = useState<string[]>([]);
  const [newImages, setNewImages] = useState<File[]>([]);
  const [mainImageIndex, setMainImageIndex] = useState(0);
  const [existingAudioUrl, setExistingAudioUrl] = useState<string>("");
  const [newAudio, setNewAudio] = useState<File | null>(null);

  // ── Load Birds from Firestore (READ) ──────────────────────
  const fetchBirds = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "birds"));
      const list: Bird[] = [];
      querySnapshot.forEach((docSnap: QueryDocumentSnapshot<DocumentData>) => {
        list.push({ id: docSnap.id, ...docSnap.data() } as Bird);
      });
      setBirds(list);
    } catch (err) {
      console.error("Error fetching birds:", err);
    }
  };

  useEffect(() => {
    fetchBirds();
  }, []);

  // ── Helper Utilities ──────────────────────────────────────
  const uploadFile = async (file: File, path: string) => {
    const fileRef = ref(storage, path);
    await uploadBytes(fileRef, file);
    return await getDownloadURL(fileRef);
  };

  const addItem = (value: string, setFn: React.Dispatch<React.SetStateAction<string[]>>, list: string[]) => {
    if (value.trim()) {
      setFn([...list, value.trim()]);
    }
  };

  const removeItem = (index: number, list: string[], setFn: React.Dispatch<React.SetStateAction<string[]>>) => {
    setFn(list.filter((_, i) => i !== index));
  };

  const resetForm = () => {
    setEditingBirdId(null);
    setName("");
    setScientificName("");
    setShortDesc("");
    setLongDesc("");
    setHabitats([]);
    setDiet([]);
    setFunFacts([]);
    setSubscription("free");
    setExistingImages([]);
    setNewImages([]);
    setMainImageIndex(0);
    setExistingAudioUrl("");
    setNewAudio(null);
  };

  // Populate form for updating
  const startEditing = (bird: Bird) => {
    if (!bird.id) return;
    setEditingBirdId(bird.id);
    setName(bird.name || "");
    setScientificName(bird.scientific_name || "");
    setShortDesc(bird.short_description || "");
    setLongDesc(bird.long_description || "");
    setHabitats(bird.habitats || []);
    setDiet(bird.diet || []);
    setFunFacts(bird.fun_facts || []);
    setSubscription(bird.subscription || "free");
    setExistingImages(bird.images || []);
    setMainImageIndex(0);
    setExistingAudioUrl(bird.sound_url || "");
    setNewImages([]);
    setNewAudio(null);
  };

  // ── CREATE / UPDATE Action ────────────────────────────────
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name) {
      alert("Name is required!");
      return;
    }

    if (!editingBirdId && newImages.length === 0) {
      alert("Please attach at least one image for a new bird!");
      return;
    }

    try {
      setLoading(true);
      const timestamp = Date.now();

      // Handle Image Uploads
      let uploadedUrls: string[] = [];
      if (newImages.length > 0) {
        for (let i = 0; i < newImages.length; i++) {
          const url = await uploadFile(
            newImages[i],
            `birds/${name}_${timestamp}/image_${i}`
          );
          uploadedUrls.push(url);
        }
      }

      const finalImages = editingBirdId
        ? [...existingImages, ...uploadedUrls]
        : uploadedUrls;

      // Handle Audio Upload
      let soundUrl = existingAudioUrl;
      if (newAudio) {
        soundUrl = await uploadFile(
          newAudio,
          `birds/${name}_${timestamp}/sound`
        );
      }

      const birdData: any = {
        name,
        scientific_name: scientificName,
        short_description: shortDesc,
        long_description: longDesc,
        habitats,
        diet,
        fun_facts: funFacts,
        subscription,
        images: finalImages,
        main_image:
          finalImages[mainImageIndex] || finalImages[0] || "",
        sound_url: soundUrl,
      };

      if (editingBirdId) {
        // UPDATE Existing Document
        await updateDoc(doc(db, "birds", editingBirdId), birdData);
        alert("Bird updated successfully! ✏️✅");
      } else {
        // CREATE New Document
        birdData.created_at = new Date();
        await addDoc(collection(db, "birds"), birdData);
        alert("Bird saved successfully! 🐦✅");
      }

      resetForm();
      fetchBirds();
    } catch (error) {
      console.error(error);
      alert("Error saving bird record ❌");
    } finally {
      setLoading(false);
    }
  };

  // ── DELETE Action ─────────────────────────────────────────
  const handleDelete = async (id: string, birdName: string) => {
    if (window.confirm(`Are you sure you want to delete "${birdName}"?`)) {
      try {
        setLoading(true);
        await deleteDoc(doc(db, "birds", id));
        alert("Bird deleted successfully! 🗑️");
        fetchBirds();
      } catch (err) {
        console.error("Error deleting document: ", err);
        alert("Failed to delete bird record.");
      } finally {
        setLoading(false);
      }
    }
  };

  // Search filter
  const filteredBirds = birds.filter((b) =>
    b.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (b.scientific_name &&
      b.scientific_name.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div style={{ padding: "20px", fontFamily: "sans-serif", maxWidth: "1200px", margin: "0 auto" }}>
      <h1 className="title">🐦 Serendib Chirps - Admin Dashboard</h1>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1.2fr", gap: "24px" }}>

        {/* LEFT COLUMN: FORM (INSERT / EDIT) */}
        <div className="card" style={{ background: "#f9f9f9", padding: "20px", borderRadius: "12px" }}>
          <h2>{editingBirdId ? "✏️ Edit Bird" : "➕ Add New Bird"}</h2>
          <form onSubmit={handleSubmit}>

            {/* BASIC INFO */}
            <div style={{ marginBottom: "15px" }}>
              <h4>Basic Info</h4>
              <input
                style={inputStyle}
                placeholder="Bird Name *"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
              <input
                style={inputStyle}
                placeholder="Scientific Name"
                value={scientificName}
                onChange={(e) => setScientificName(e.target.value)}
              />
            </div>

            {/* DESCRIPTION */}
            <div style={{ marginBottom: "15px" }}>
              <h4>Descriptions</h4>
              <textarea
                style={textareaStyle}
                placeholder="Short Description"
                value={shortDesc}
                onChange={(e) => setShortDesc(e.target.value)}
              />
              <textarea
                style={textareaStyle}
                placeholder="Long Description"
                value={longDesc}
                onChange={(e) => setLongDesc(e.target.value)}
              />
            </div>

            {/* LIST BUILDERS */}
            <ListBuilder label="Habitats" list={habitats} setList={setHabitats} inputVal={habitatInput} setInputVal={setHabitatInput} addItem={addItem} removeItem={removeItem} />
            <ListBuilder label="Diet" list={diet} setList={setDiet} inputVal={dietInput} setInputVal={setDietInput} addItem={addItem} removeItem={removeItem} />
            <ListBuilder label="Fun Facts" list={funFacts} setList={setFunFacts} inputVal={factInput} setInputVal={setFactInput} addItem={addItem} removeItem={removeItem} />

            {/* IMAGES */}
            <div style={{ marginBottom: "15px" }}>
              <h4>Images</h4>
              {existingImages.length > 0 && (
                <div style={{ marginBottom: "8px" }}>
                  <p style={{ fontSize: "12px", margin: "4px 0" }}>Existing Images:</p>
                  <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                    {existingImages.map((img, idx) => (
                      <div key={idx} style={{ position: "relative" }}>
                        <img src={img} alt="preview" style={{ width: "50px", height: "50px", objectFit: "cover", borderRadius: "4px" }} />
                        <span
                          style={{ position: "absolute", top: -5, right: -5, background: "red", color: "white", borderRadius: "50%", padding: "2px 5px", fontSize: "10px", cursor: "pointer" }}
                          onClick={() => setExistingImages(existingImages.filter((_, i) => i !== idx))}
                        >
                          ✕
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              <input
                type="file"
                multiple
                accept="image/*"
                onChange={(e) => setNewImages(e.target.files ? Array.from(e.target.files) : [])}
              />
            </div>

            {/* AUDIO */}
            <div style={{ marginBottom: "15px" }}>
              <h4>Bird Sound Audio</h4>
              {existingAudioUrl && (
                <div style={{ marginBottom: "8px" }}>
                  <p style={{ fontSize: "12px", margin: "4px 0" }}>Current Audio:</p>
                  <audio controls src={existingAudioUrl} style={{ width: "100%" }} />
                </div>
              )}
              <input
                type="file"
                accept="audio/*"
                onChange={(e) => setNewAudio(e.target.files?.[0] || null)}
              />
            </div>

            {/* SUBSCRIPTION */}
            <div style={{ marginBottom: "15px" }}>
              <h4>Subscription Access</h4>
              <select
                style={inputStyle}
                value={subscription}
                onChange={(e) => setSubscription(e.target.value as "free" | "premium")}
              >
                <option value="free">Free Access</option>
                <option value="premium">Premium Access Only</option>
              </select>
            </div>

            {/* ACTIONS */}
            <div style={{ display: "flex", gap: "10px" }}>
              <button
                type="submit"
                disabled={loading}
                style={{ ...btnStyle, background: editingBirdId ? "#2196F3" : "#4CAF50" }}
              >
                {loading ? "Processing..." : editingBirdId ? "Update Bird" : "Save Bird"}
              </button>
              {editingBirdId && (
                <button
                  type="button"
                  onClick={resetForm}
                  style={{ ...btnStyle, background: "#9E9E9E" }}
                >
                  Cancel
                </button>
              )}
            </div>

          </form>
        </div>

        {/* RIGHT COLUMN: READ / MANAGEMENT VIEW */}
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
            <h2>📋 Bird Database ({filteredBirds.length})</h2>
            <input
              style={{ ...inputStyle, width: "200px", margin: 0 }}
              placeholder="🔍 Search bird name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxHeight: "80vh", overflowY: "auto" }}>
            {filteredBirds.map((bird) => (
              <div
                key={bird.id}
                style={{
                  display: "flex",
                  gap: "12px",
                  background: "white",
                  border: "1px solid #ddd",
                  padding: "12px",
                  borderRadius: "8px",
                  alignItems: "center",
                }}
              >
                <img
                  src={bird.main_image || (bird.images && bird.images[0]) || "https://via.placeholder.com/80"}
                  alt={bird.name}
                  style={{ width: "80px", height: "80px", objectFit: "cover", borderRadius: "6px" }}
                />

                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <strong style={{ fontSize: "16px" }}>{bird.name}</strong>
                    <span
                      style={{
                        fontSize: "10px",
                        padding: "2px 8px",
                        borderRadius: "12px",
                        background: bird.subscription === "premium" ? "#FFE0B2" : "#E8F5E9",
                        color: bird.subscription === "premium" ? "#E65100" : "#2E7D32",
                        fontWeight: "bold",
                        textTransform: "uppercase",
                      }}
                    >
                      {bird.subscription}
                    </span>
                  </div>
                  // ✅ CORRECT
                  <p style={{ margin: "2px 0", fontSize: "12px", color: "#666", fontStyle: "italic" }}>
                    {bird.scientific_name || "No scientific name"}
                  </p>
                  {bird.sound_url && (
                    <audio controls src={bird.sound_url} style={{ height: "24px", marginTop: "4px" }} />
                  )}
                </div>

                <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                  <button
                    onClick={() => startEditing(bird)}
                    style={{ ...actionBtnStyle, background: "#2196F3" }}
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => bird.id && handleDelete(bird.id, bird.name)}
                    style={{ ...actionBtnStyle, background: "#F44336" }}
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}

// ── Helper Component for Custom Lists ────────────────────────
interface ListBuilderProps {
  label: string;
  list: string[];
  setList: React.Dispatch<React.SetStateAction<string[]>>;
  inputVal: string;
  setInputVal: React.Dispatch<React.SetStateAction<string>>;
  addItem: Function;
  removeItem: Function;
}

const ListBuilder: React.FC<ListBuilderProps> = ({
  label,
  list,
  setList,
  inputVal,
  setInputVal,
  addItem,
  removeItem,
}) => (
  <div style={{ marginBottom: "15px" }}>
    <h4>{label}</h4>
    <div style={{ display: "flex", gap: "8px", marginBottom: "6px" }}>
      <input
        style={{ ...inputStyle, marginBottom: 0 }}
        value={inputVal}
        onChange={(e) => setInputVal(e.target.value)}
      />
      <button
        type="button"
        onClick={() => {
          addItem(inputVal, setList, list);
          setInputVal("");
        }}
        style={{ padding: "0 12px", background: "#333", color: "white", border: "none", borderRadius: "4px" }}
      >
        +
      </button>
    </div>
    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
      {list.map((item, i) => (
        <span
          key={i}
          style={{
            background: "#E0E0E0",
            padding: "4px 8px",
            borderRadius: "4px",
            fontSize: "12px",
            display: "inline-flex",
            alignItems: "center",
            gap: "6px",
          }}
        >
          {item}
          <b style={{ cursor: "pointer", color: "#999" }} onClick={() => removeItem(i, list, setList)}>
            ✕
          </b>
        </span>
      ))}
    </div>
  </div>
);

// ── Common Styling Tokens ─────────────────────────────────
const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "8px 12px",
  marginBottom: "8px",
  borderRadius: "4px",
  border: "1px solid #ccc",
  boxSizing: "border-box",
};

const textareaStyle: React.CSSProperties = {
  ...inputStyle,
  height: "60px",
  resize: "vertical",
};

const btnStyle: React.CSSProperties = {
  padding: "10px 16px",
  color: "white",
  border: "none",
  borderRadius: "6px",
  cursor: "pointer",
  fontWeight: "bold",
  flex: 1,
};

const actionBtnStyle: React.CSSProperties = {
  padding: "6px 12px",
  color: "white",
  border: "none",
  borderRadius: "4px",
  fontSize: "12px",
  cursor: "pointer",
};

export default App;