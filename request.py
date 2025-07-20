import requests

def send_message(message):
    api_url = "https://0nc0u7bbrh.execute-api.us-east-1.amazonaws.com/chat"
    response = requests.post(api_url, json={"messages": [build_message(message)]})
    model_response = response.json()['content'][0]['text']
    print(f"\n{model_response}\n")

def build_message(prompt):
    return {
        "role": "user",
        "content": prompt
    }

def main():
    liveness_prompt = "Hi! Tell me about the healthcare advocacy company called Solace"

    print(f"Testing Liveness - Sending Message:\n\"{liveness_prompt}\"\n")
    send_message(liveness_prompt)
    user_input = ""

    while user_input.lower() != "exit":
        user_input = input("Enter your message: ")
        if user_input.lower() != "exit":
            send_message(user_input)

    print("Session Ended")

if __name__ == "__main__":
    main()