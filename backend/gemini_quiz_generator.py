# gemini_quiz_generator.py
import os
import json
import random
from datetime import datetime
import google.generativeai as genai

genai.configure(api_key=os.getenv("YOUR_API_KEY") or "YOUR_API_KEY")
model = genai.GenerativeModel("gemini-1.5-flash")

def generate_prompt(user_topic: str, context_text: str = "") -> str:
    question_types = ['single', 'multiple', 'open', 'reorder']
    weights = [0.4, 0.3, 0.2, 0.1]
    selected_type = random.choices(question_types, weights=weights, k=1)[0]

    system_instruction = f"""
You are an expert quiz generator.
Generate quiz on: {user_topic}
Respond in JSON list format with type, question, options, correctAnswer, explanation, etc.
{f"\nContext:\n{context_text}" if context_text else ""}
    """

    return system_instruction

def call_gemini(prompt: str) -> dict:
    try:
        response = model.generate_content(prompt)
        raw = response.text.strip()
        return json.loads(raw)
    except Exception as e:
        return {"error": str(e), "raw_output": raw if 'raw' in locals() else ""}
