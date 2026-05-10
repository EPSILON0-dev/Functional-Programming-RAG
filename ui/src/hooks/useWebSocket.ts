// TODO unslopify

export class WebSocketManager {
  private ws: WebSocket | null = null;
  private userId: string;
  private reconnectAttempts = 0;
  private reconnectTimeout: number | null = null;
  private intentionallyClosed = false;
  private readonly maxReconnectDelay = 30000; // 30 seconds
  private readonly initialReconnectDelay = 1000; // 1 second

  constructor(userId: string) {
    this.userId = userId;
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
      // TODO don't do this
      this.ws?.send(JSON.stringify({
        topic: `user:${this.userId}`,
        event: "phx_join",
        payload: {
          token: token
        },
        ref: Math.random().toString(),
      }));
    };

    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);

      // Handle incoming messages
      if (message.event === "response_complete") {
        console.log("Got response:", message.payload.content);
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

  public subscribeToJob(chatId: string) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        topic: `user:${this.userId}`,
        event: "subscribe_job",
        payload: { chat_id: chatId },
        ref: Math.random().toString()
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

export function createWebSocketManager(userId: string) {
  return new WebSocketManager(userId);
}
