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

  private async fetchToken(): Promise<string> {
    return await fetch("/api/auth/wstoken", {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    }).then(async response => {
      if (!response.ok) {
        throw new Error("Failed to get WebSocket token.");
      }
      const { token } = await response.json();
      return await token;
    });
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

  private async joinTopic(token: string, topic: string) {
    this.ws?.send(JSON.stringify({
      topic: topic,
      event: "phx_join",
      payload: {
        token: token
      },
      ref: Math.random().toString(),
    }));
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

  private async heartbeatLoop() {
    await new Promise(resolve => setTimeout(resolve, this.heartbeatInterval));
    while (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.sendHeartbeat();
      await new Promise(resolve => setTimeout(resolve, this.heartbeatInterval));
    }
  }

  private handleIncomingResponse(message: any) {
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

  private async connect() {
    // TODO Move the token to the headers
    const token = await this.fetchToken();
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/api/websocket?token=${token}`;

    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = async () => {
      console.log("WebSocket connected");
      this.reconnectAttempts = 0;

      // Join the user channel
      await this.joinTopic(token, `user:${this.userId}`);

      // Periodically send heartbeat messages to keep the connection alive
      this.heartbeatLoop();
    };

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data);

      switch (data.event) {
        case "response_complete":
        case "response_new":
          this.handleIncomingResponse(data);
          break;
        case "phx_reply":
          // We ignore them but they don't need to be logged
          break;
        default:
          console.warn("Unhandled message event:", data.event);
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
