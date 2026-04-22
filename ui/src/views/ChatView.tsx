import { useState, useEffect } from 'react';
import { UserMessage } from "../components/UserMessage"
import { AssistantMessage } from "../components/AssistantMessage"
import { ChatInput } from "../components/ChatInput"
import type { NamedIdentifier, Conversation } from '@/types';

interface Props {
    viewedConversation: NamedIdentifier | null
};

export function ChatView(props: Props): React.JSX.Element {
    const [conversation, setConversation] = useState<Conversation>();

    const fetchConversation = () => {
        if (!props.viewedConversation) return;
        fetch(`http://localhost:8000/api/conversations/${props.viewedConversation.id}/messages`)
            .then(res => res.json())
            .then(data => setConversation(data))
            .catch(err => console.error("Fetch failed:", err));
    };

    useEffect(() => {
        fetchConversation();
        console.log(`Fetching conversation ID: ${props.viewedConversation?.id}`);
    }, [props.viewedConversation]);

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0 px-4 py-2 border-b">
                <div className="flex-row flex items-center gap-2">
                    <h1 className="mx-auto">{conversation?.label}</h1>
                </div>
            </header>

            <main className="flex-1 min-w-0 overflow-y-auto">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <div className="h-8" />
                    {conversation?.messages.map((item, index) => (
                        <div key={index}>
                            {item.role === "user" ? (
                                <UserMessage message={item.content} />
                            ) : (
                                <AssistantMessage message={item.content} />
                            )}
                        </div>
                    ))}
                </div>
            </main>

            <footer className="shrink-0 px-4 py-2 border-t">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <ChatInput />
                </div>
            </footer>
        </div>
    )
}
