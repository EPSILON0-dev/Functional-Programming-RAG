export async function startNewChat(message: string): Promise<void> {
    await fetch("/api/chats/new", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ first_message: message }),
    }).catch((error) => {
        console.error("Error sending message:", error)
    })
}
