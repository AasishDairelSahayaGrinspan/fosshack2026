import random
import time

# Memory
user_name = None

# Welcome
def welcome():
    print("\n💙 Welcome to UNRAVEL AI")
    print("Let’s gently untangle your thoughts...")
    print("Type 'exit' to quit.\n")

# Emotion keywords
emotion_map = {
    "sad": ["sad", "depressed", "down", "lonely", "cry"],
    "stress": ["stress", "overwhelmed", "tired", "pressure"],
    "anxiety": ["anxious", "panic", "fear", "worried", "nervous"],
    "anger": ["angry", "frustrated", "annoyed"],
    "happy": ["happy", "good", "great", "excited"]
}

# Responses
responses = {
    "sad": [
        "I'm really sorry you're feeling this way. Want to talk more?",
        "It's okay to feel sad. I'm here with you 💙",
        "Try expressing your feelings in writing or talking to someone you trust."
    ],
    "stress": [
        "Take a deep breath: inhale 4 sec, hold, exhale slowly.",
        "Break tasks into small steps. You don’t have to do everything at once.",
        "Try taking a short mindful break."
    ],
    "anxiety": [
        "You are safe. Let’s ground you.",
        "Try the 5-4-3-2-1 method to calm yourself.",
        "This feeling will pass. Stay with me."
    ],
    "anger": [
        "Pause before reacting. You deserve calm.",
        "Try releasing tension through movement or deep breathing.",
        "What triggered this feeling?"
    ],
    "happy": [
        "That’s amazing 😊 What made you feel this way?",
        "Hold onto this positivity 💫",
        "Spread your happiness!"
    ],
    "default": [
        "I’m listening. Tell me more 💙",
        "That sounds important. Can you explain?",
        "Let’s work through this together."
    ]
}

# Detect emotion
def detect_emotion(user_input):
    for emotion, words in emotion_map.items():
        for word in words:
            if word in user_input:
                return emotion
    return "default"

# Smart chatbot
def generate_response(user_input):
    global user_name
    text = user_input.lower()

    # Name detection
    if "my name is" in text:
        user_name = user_input.split("my name is")[-1].strip()
        return f"Nice to meet you, {user_name} 💙 I'm UNRAVEL."

    # Greeting
    if any(word in text for word in ["hi", "hello", "hey"]):
        return f"Hello {user_name if user_name else ''} 💙 How are you feeling today?"

    # Gratitude
    if any(word in text for word in ["thank", "thanks", "thx"]):
        return "You're always welcome 💙 I'm here for you."

    # Feeling alone
    if "alone" in text:
        return "You're not alone. I'm here with you 💙"

    # Sleep help
    if "sleep" in text:
        return "Try calming music, no screens, and slow breathing before bed."

    # Study help
    if "study" in text:
        return "Try Pomodoro: 25 min focus + 5 min break."

    # Crisis handling
    if "suicide" in text or "kill myself" in text:
        return "Please talk to someone you trust or a professional immediately. You matter 💙"

    # Emotion-based response
    emotion = detect_emotion(text)
    return random.choice(responses[emotion])

# Chat loop
def chat():
    welcome()

    while True:
        user_input = input("You: ")

        if user_input.lower() == "exit":
            print("UNRAVEL: Take care 💙 You are important.")
            break

        print("UNRAVEL is thinking...")
        time.sleep(1)

        response = generate_response(user_input)
        print("UNRAVEL:", response)

# Run
chat()