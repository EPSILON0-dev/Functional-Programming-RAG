import { useNavigate, useParams } from "react-router-dom";
import {
  AssistantMessage,
  ErrorMessage,
  GeneratingMessage,
  UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import { AppContext } from "@/AppContext";
import { useContext, useEffect, useState } from "react";
import type { Message } from "@/types/types";
import { IconAlertTriangleFilled } from "@tabler/icons-react";
import { Button } from "@/components/ui/button";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardFooter,
} from "@/components/ui/card";
import { toast } from "sonner";

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

  const onMessageSent = async (message: string, config: any) => {
    if (!chatId) return;

    try {
      const response = await fetch(`/api/chats/${chatId}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ content: message, config }),
      });

      if (response.ok) {
        const confirmMessage = await response.json();
        ctx?.dispatch({
          type: "ADD_MESSAGE",
          payload: { chatId, message: confirmMessage },
        });
      } else if (response.status === 425) {
        console.error("Server is still processing previous message");
        toast.error("Not so fast.", {
          description: "The server is still processing your previous message. Please wait a moment before sending another one."
        });
      } else {
        console.error("Failed to send message");
        toast.error("Failed to send message", {
          description: "An error occurred while sending message. Please verify the API key and try again."
        });
      }
    } catch (error) {
      console.error("Error sending message:", error);
    }
  }

  const deleteMessage = async (messageId: string) => {
    if (!chatId) return;

    try {
      const response = await fetch(`/api/chats/${chatId}/messages/${messageId}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (response.ok) {
        toast.success("Message deleted");
        // The message will be removed via WebSocket event, but as fallback we can also update locally
        ctx?.dispatch({
          type: "SET_MESSAGES",
          payload: {
            chatId,
            messages: (messages || []).filter(msg => msg.id !== messageId)
          },
        });
      } else {
        toast.error("Failed to delete message");
      }
    } catch (error) {
      console.error("Error deleting message:", error);
      toast.error("Failed to delete message");
    }
  }

  const retryGeneration = async (_: string) => {
    if (!chatId) return;

    try {
      const response = await fetch(`/api/chats/${chatId}/retry`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ config: ctx?.state.pipelineConfig }),
      });

      if (response.ok) {
        toast.success("Retrying generation...");
        // The error message will be removed and new response will arrive via WebSocket
      } else if (response.status === 422) {
        toast.error("No error message to retry");
      } else if (response.status === 425) {
        toast.error("Generation already running. Please wait.");
      } else {
        toast.error("Failed to retry generation");
      }
    } catch (error) {
      console.error("Error retrying generation:", error);
      toast.error("Failed to retry generation");
    }
  }

  const handleAction = (isLastMessage: boolean, messageId: string) => {
    if (isLastMessage) {
      retryGeneration(messageId);
    } else {
      deleteMessage(messageId);
    }
  };

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
            <ErrorBoundary>
              {messages?.map((item, index) => (
                <div key={index}>
                  {item.role === "user" ? (
                    <UserMessage message={item.content} />
                  ) : item.role === "assistant" ? (
                    <AssistantMessage message={item} />
                  ) : item.role === "generating" ? (
                    <GeneratingMessage message={item.content} />
                  ) : (
                    <ErrorMessage
                      message={item.content}
                      details={item.metadata?.error}
                      isLastMessage={index === (messages?.length ?? 0) - 1}
                      onAction={() => handleAction(index === (messages?.length ?? 0) - 1, item.id)}
                    />
                  )}
                </div>
              ))}
            </ErrorBoundary>
          }
        </div>
      </main>

      <footer className="shrink-0 px-4 py-2 border-t">
        <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
          <ErrorBoundary>
            <ChatInput onMessageSent={onMessageSent} />
          </ErrorBoundary>
        </div>
      </footer>
    </div>
  );
}
