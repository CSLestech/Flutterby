import onnxruntime as ort
from flask import Flask, request, jsonify
import numpy as np
import joblib
import cv2
import base64

app = Flask(__name__)

# Load the ONNX model (DeiT for feature extraction)
onnx_model = ort.InferenceSession("deit_model.onnx")

# Load the SVM model (saved as joblib)
svm_model = joblib.load("svm_model_20241128_151612.joblib")

# Preprocessing function for image
def preprocess_image(image):
    # Resize the image to the expected size (224x224 for DeiT)
    image_resized = cv2.resize(image, (224, 224))
    # Normalize the image (DeiT might expect normalized images)
    image_normalized = image_resized / 255.0
    # Rearrange the channels to be in the (C, H, W) format (3, 224, 224)
    image_transposed = np.transpose(image_normalized, (2, 0, 1))  # Convert HxWxC to CxHxW
    # Expand dimensions to create a batch (1, 3, 224, 224)
    image_input = np.expand_dims(image_transposed, axis=0).astype(np.float32)
    return image_input

# Route to handle predictions
@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get the input data (image)
        data = request.get_json()  # Assumes the request contains JSON data
        img_str = data['image']  # The image is expected to be base64 encoded

        # Decode the base64 image string
        img_data = np.frombuffer(base64.b64decode(img_str), dtype=np.uint8)
        img = cv2.imdecode(img_data, cv2.IMREAD_COLOR)  # Decode as a color image

        # Preprocess image for DeiT model
        preprocessed_image = preprocess_image(img)

        # Run the ONNX model for feature extraction
        onnx_inputs = {onnx_model.get_inputs()[0].name: preprocessed_image}
        feature_vector = onnx_model.run(None, onnx_inputs)[0]  # Extracted feature vector

        # Use the SVM model to classify the extracted features
        prediction = svm_model.predict(feature_vector)
        prediction_prob = svm_model.predict_proba(feature_vector)  # Assuming SVM model has this method

        # Set threshold confidence to 0.5
        threshold = 0.5
        predicted_class = prediction[0] 
        confidence_score = np.max(prediction_prob)  # Get the maximum confidence score
        
        # If confidence score is below 0.5, label as uncertain or handle accordingly
        if confidence_score < threshold:
            predicted_class = 'Uncertain'  # You can set this to any label you'd prefer
            confidence_score = None  # No confidence score if it's uncertain

        # Print prediction and confidence score for logging
        print(f"Prediction: {predicted_class}, Confidence: {confidence_score}")

        # Return the classification result and confidence score
        return jsonify({
            "prediction": predicted_class,
            "confidence_score": confidence_score
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(debug=True, host='192.168.1.10', port=5000)
