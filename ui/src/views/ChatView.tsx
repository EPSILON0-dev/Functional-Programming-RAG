import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import {
    AssistantMessage,
    GeneratingMessage,
    UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import type { Chat } from '@/types';
import { AppContext } from "@/AppContext";
import { useContext, useEffect } from "react";

export function ChatView(): React.JSX.Element {
    const ctx = useContext(AppContext);
    const { chatId } = useParams<{ chatId: string }>();

    const { data: chat, isLoading: isChatLoading, isError: isChatError } = useQuery<Chat>({
        queryKey: ["chat", chatId],
        queryFn: async () => {
            const response = await fetch(`/api/chats/${chatId}`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            return response.json();
        },
    });

    useEffect(() => {
        if (!chatId) return;

        const fetchMessages = async () => {
            const response = await fetch(`/api/chats/${chatId}/messages`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            const messages = await response.json();
            ctx?.dispatch({ type: "SET_MESSAGES", payload: { chatId, messages } });
        };

        fetchMessages();
    }, [chatId]);

    const messages = chatId ? ctx?.state.messages[chatId] : undefined;

    const onMessageSent = async (message: string) => {
        if (!chatId) return;

        await fetch(`/api/chats/${chatId}/messages`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ content: message }),
        }).then((response) => response.json()).then((message) => {
            ctx?.dispatch({
                type: "ADD_MESSAGE",
                payload: { chatId, message },
            });
        }).catch((error) => {
            console.error("Error sending message:", error)
        })
    }

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0 px-4 py-2 border-b">
                <div className="flex-row flex items-center gap-2">
                    <h1 className="mx-auto">{chat?.name || "Loading..."}</h1>
                </div>
            </header>

            <main className="flex-1 min-w-0 overflow-y-auto">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <div className="h-8" />
                    {messages?.map((item, index) => (
                        <div key={index}>
                            {item.role === "user" ? (
                                <UserMessage message={item.content} />
                            ) : item.role === "assistant" ? (
                                <AssistantMessage message={item.content} />
                            ) : (
                                <GeneratingMessage />
                            )}
                        </div>
                    ))}
                </div>
            </main>

            <footer className="shrink-0 px-4 py-2 border-t">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <ChatInput onMessageSent={onMessageSent} />
                </div>
            </footer>
        </div>
    );
}
