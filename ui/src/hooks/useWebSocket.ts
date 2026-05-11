import { AppContext } from "@/AppContext";
import React, { useContext } from "react";

export class WebSocketManager {
  private ws: WebSocket | null = null;
  private userId: string;
  private dispatch: React.Dispatch<any> = () => { };
  private reconnectAttempts = 0;
  private reconnectTimeout: number | null = null;
  private intentionallyClosed = false;
  private readonly heartbeatInterval = 30000; // 30 seconds
  private readonly maxReconnectDelay = 30000; // 30 seconds
  private readonly initialReconnectDelay = 1000; // 1 second

  constructor(userId: string, dispatch: React.Dispatch<any>) {
    this.userId = userId;
    this.dispatch = dispatch;
    this.connect();
  }

  private async connect() {
    const token = fetch("/api/auth/wstoken", {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    }).then(async response => {
      if (!response.ok) {
        throw new Error("Failed to get WebSocket token.");
      }
      const { token } = await response.json();
      return token;
    });

    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/api/websocket?token=${await token}`;

    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log("WebSocket connected");
      this.reconnectAttempts = 0;

      // Join the user channel
      this.ws?.send(JSON.stringify({
        topic: `user:${this.userId}`,
        event: "phx_join",
        payload: {
          token: token
        },
        ref: Math.random().toString(),
      }));

      this.heartbeatLoop();
    };

    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);

      // Handle incoming messages
      if (message.event === "response_complete" || message.event === "response_new") {
        console.log("Received message:", message);
        this.dispatch({
          type: "ADD_MESSAGE",
          payload: {
            chatId: message.payload.chat_id,
            message: {
              id: message.payload.id,
              role: message.payload.role,
              content: message.payload.content || "",
              timestamp: message.payload.timestamp,
            }
          }
        });
      }
    };

    this.ws.onerror = (error) => {
      console.error("WebSocket error:", error);
    };

    this.ws.onclose = () => {
      console.log("WebSocket disconnected");

      if (!this.intentionallyClosed) {
        this.scheduleReconnect();
      }
    };
  }

  private scheduleReconnect() {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
    }

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 64s, ...
    const delay = Math.min(
      this.initialReconnectDelay * Math.pow(2, this.reconnectAttempts),
      this.maxReconnectDelay
    );

    this.reconnectAttempts++;
    console.log(`WebSocket reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    this.reconnectTimeout = setTimeout(() => {
      this.connect();
    }, delay);
  }

  private async heartbeatLoop() {
    await new Promise(resolve => setTimeout(resolve, this.heartbeatInterval));
    while (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.sendHeartbeat();
      await new Promise(resolve => setTimeout(resolve, this.heartbeatInterval));
    }
  }

  private sendHeartbeat() {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        topic: "phoenix",
        event: "heartbeat",
        payload: {},
        ref: Math.random().toString(),
      }));
    }
  }

  public disconnect() {
    this.intentionallyClosed = true;
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
      this.reconnectTimeout = null;
    }
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.close();
    }
  }
}

export function createWebSocketManager(userId: string, dispatch: React.Dispatch<any>) {
  return new WebSocketManager(userId, dispatch);
}
