import { useContext } from "react";
import { ChatInput } from "../components/ChatInput"
// import { DatabaseDropdown } from "../components/DatabaseDropdown"
import { useNavigate } from "react-router-dom";
import { AppContext } from "@/AppContext";
import type { Conversation, Message } from "@/types";

export function NewChatView(): React.JSX.Element {
    const navigate = useNavigate();
    const ctx = useContext(AppContext);

    // TODO add chat
    const startNewChat = async (message: string): Promise<void> => {
        const response = await fetch("/api/chats/new", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ first_message: message }),
        }).catch((error) => {
            console.error("Error sending message:", error)
        })

        if (response && response.ok) {
            const { chat, message }: { chat: Conversation; message: Message } = await response.json();
            const { id } = chat;
            navigate(`/chat/${id}`);
            const messagePayload = { chatId: id, messages: [message] };
            ctx?.dispatch({ type: "SET_MESSAGES", payload: messagePayload });
            ctx?.dispatch({ type: "ADD_CONVERSATION", payload: chat });
        } else {
            console.error("Failed to start new chat");
        }
    }

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <main className="m-auto max-w-4xl w-full">
                <div className="mx-8">
                    <h1 className="text-3xl text-center mb-12">Select the database and ask a question</h1>
                    <ChatInput onMessageSent={startNewChat} />
                    {/*<div className="ml-2 mt-2">
                        <DatabaseDropdown />
                    </div>*/}
                </div>
            </main>
        </div>
    )
}
