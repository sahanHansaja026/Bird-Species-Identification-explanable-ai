# Explainable Audio-Based Machine Learning for Bird Species Identification

## Authors

* **D.M.S.Y. Jayasundara¹**
* **I.W.S.C.R. Rajaguru¹**
* **M.A.D.H. Wijewardhana¹**
* **M.M.S. Hansaja²**

¹ Department of Data Science
² Department of Software Engineering
Sri Lanka Technological Campus (Pvt) Ltd, Sri Lanka

**Supervisors:** Ms. Buddhima Lakchani, Mr. Chameera De Silva

---

## Repository Status

**Phase:** Model Testing (Ongoing)

---

## Project Progress

| Task                           | Description                               | Status        |
| ------------------------------ | ----------------------------------------- | ------------- |
| Dataset Collection             | Bird audio data gathering & organization  | ✅ Completed   |
| Model Training                 | Training ML model with extracted features | ✅ Completed   |
| Model Testing                  | Evaluating model performance              | 🔄 In Progress |
| UI/UX Design (Figma)           | Designing child-friendly interfaces       | 🔄 In Progress |
| Mobile Application Development | Building the mobile application           | 🔄 In Progress |
| Firebase Integration           | Backend connection and data handling      | ✅ Completed   |

---

## Abstract

Bird species identification using audio signals is an effective approach for environmental education, particularly in regions with high biodiversity such as Sri Lanka. While recent machine learning techniques provide high classification accuracy, most existing systems lack explainability, making them unsuitable for child-centered learning environments.

This research aims to develop an **explainable, child-friendly bird sound identification system** using audio-based machine learning methods. The repository supports this research by providing curated bird audio datasets and trained models for common Sri Lankan species.

---

## Research Objectives

* Collect and organize bird sound recordings relevant to Sri Lanka
* Develop and train audio-based machine learning models
* Evaluate model performance and improve accuracy
* Enable explainable AI research for educational applications

---

## Dataset Description

The repository includes bird audio recordings collected from:

* **Xeno-canto**
* **Sri Lankan Nature Sounds Database**
* **Field recordings (Kegalle region)**

The dataset focuses on **common Sri Lankan bird species** and supports feature extraction techniques such as:

* MFCCs (Mel-Frequency Cepstral Coefficients)
* Mel-spectrograms

---

## Current Progress

* Dataset collection and preprocessing completed
* Feature extraction implemented
* Model training completed
* Model testing and evaluation in progress
* UI/UX design in progress
* Mobile app development in progress
* Firebase successfully integrated

---

## Planned Work (Next Steps)

* Improve model accuracy through tuning and optimization
* Implement explainable AI techniques (e.g., Grad-CAM)
* Finalize mobile application development
* Deploy and test real-world usage

---

## Project Structure

The repository is organized into multiple components, each responsible for a specific part of the system:

```
bird-ai-backend/   # FastAPI backend for bird identification & explainable AI
bird-web/          # Web system for managing bird data (CRUD + audio upload)
bird_app/          # Flutter mobile app for children
dataset/           # Training dataset (bird audio data)
test-data/         # Dataset used for model testing & evaluation
renamefiles.py     # Utility script for preprocessing/renaming dataset files
.gitignore
README.md
```

---

## Component Overview

### 🔹 bird-ai-backend

FastAPI backend responsible for:

* Bird sound classification
* Explainable AI integration (e.g., Grad-CAM)
* Serving predictions to applications

### 🔹 bird-web

Web application used for:

* Insert, update, delete bird details
* Upload and manage bird audio files

### 🔹 bird_app

Flutter mobile application designed for:

* Child-friendly bird identification
* Interactive learning experience
* API integration with backend

### 🔹 dataset

* Bird audio recordings for **model training**
* Supports feature extraction (MFCC, Mel-spectrograms)

### 🔹 test-data

* Used for **model testing and evaluation**
* Helps validate performance and accuracy

### 🔹 renamefiles.py

* Utility script for dataset preprocessing
* File renaming and organization

---

## Disclaimer

This repository is part of an ongoing undergraduate research project.
The contents will continue to evolve as testing and development progress.
