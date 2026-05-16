import { useNavigate, useParams } from "react-router-dom";
import {
  AssistantMessage,
  GeneratingMessage,
  UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import { AppContext } from "@/AppContext";
import { useContext, useEffect, useState } from "react";
import type { Message } from "@/types";
import { IconAlertTriangleFilled } from "@tabler/icons-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardFooter,
} from "@/components/ui/card";

export function ChatView(): React.JSX.Element {
  const ctx = useContext(AppContext);
  const navigate = useNavigate();
  const { chatId } = useParams<{ chatId: string }>();
  const [chatError, setChatError] = useState<boolean>(false);

  useEffect(() => {
    if (!chatId) return;

    const fetchMessages = async () => {
      await fetch(`/api/chats/${chatId}/messages`).then(async (res) => {
        if (!res.ok) {
          setChatError(true);
          throw new Error("Failed to fetch messages");
        }

        const messages: Message[] = await res.json();
        setChatError(false);
        ctx?.dispatch({ type: "SET_MESSAGES", payload: { chatId, messages } });
      }).catch((error) => {
        console.error("Error fetching messages:", error);
      });
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

  const handleRefresh = () => {
    setChatError(false);
    window.location.reload();
  };

  const handleCreateNewChat = () => {
    navigate('/');
  };

  return (
    <div className="flex flex-col h-screen min-w-0 flex-1">
      <header className="shrink-0 px-4 py-2 border-b">
        <div className="flex-row flex items-center gap-2">
          <h1 className="mx-auto">{
            chatError ? "Error loading chat" :
              ctx?.state.chats?.find(chat => chat.id === chatId)?.name || "Loading"
          }</h1>
        </div>
      </header>

      <main className="flex-1 min-w-0 overflow-y-auto">
        <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
          <div className="h-8" />
          {chatError ? (
            <div className="flex items-center justify-center h-full">
              <Card className="w-full max-w-md border-destructive/50">
                <CardHeader>
                  <div className="flex items-center gap-3">
                    <IconAlertTriangleFilled className="h-5 w-5 text-destructive" />
                    <CardTitle>Failed to Load Chat</CardTitle>
                  </div>
                  <CardDescription>
                    We couldn't load this chat. The chat may have been deleted or there's a connection issue.
                  </CardDescription>
                </CardHeader>
                <CardFooter className="flex gap-3">
                  <Button
                    onClick={handleRefresh}
                    className="flex-1"
                  >
                    Try Again
                  </Button>
                  <Button
                    variant="outline"
                    onClick={handleCreateNewChat}
                    className="flex-1"
                  >
                    New Chat
                  </Button>
                </CardFooter>
              </Card>
            </div>
          ) :
            messages?.map((item, index) => (
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
