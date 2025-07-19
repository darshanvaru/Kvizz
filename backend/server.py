# server.py
from flask import Flask, request, jsonify
from gemini_quiz_generator import generate_prompt, call_gemini
import os

app = Flask(__name__)

@app.route('/generate', methods=['POST'])
def generate_quiz():
    prompt = request.form.get('prompt', '')
    if not prompt:
        return jsonify({"error": "Prompt is required"}), 400

    generated_prompt = generate_prompt(prompt)
    result = call_gemini(generated_prompt)
    return jsonify(result)

if __name__ == '__main__':
    os.environ['AIzaSyA_ad0Bhjqk2e4XOFfNCvW-Vdpj2udcFRI'] = "AIzaSyA_ad0Bhjqk2e4XOFfNCvW-Vdpj2udcFRI"  # Optional: Or use .env
    app.run(host="0.0.0.0", port=8000, debug=True)
