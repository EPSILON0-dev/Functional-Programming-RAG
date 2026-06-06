import { createContext, useEffect, useReducer } from "react";
import type { Conversation, Message, NamedIdentifier } from "./types/types";
import { QueryClient } from "@tanstack/react-query";
import { authGetCurrentUser, authLogout, type AuthUser } from "./lib/auth";
import { WebSocketManager } from "./lib/ws";
import { PRESET_BALANCED, type PipelineConfig } from "./types/pipelineConfig";

type Theme = "light" | "dark";

const storedTheme = (localStorage.getItem("theme") as Theme | null) ?? "light";

const initialState: AppState = {
  chats: null,
  websocket: null,
  connectionError: false,
  selectedDatabase: null,
  theme: storedTheme,
  currentUser: await authGetCurrentUser(),
  pipelineConfig: PRESET_BALANCED.config,
  messages: {},
  chatRefreshCounter: 0,
};

interface AppState {
  chats: Conversation[] | null;
  websocket: WebSocketManager | null;
  connectionError: boolean;
  selectedDatabase: NamedIdentifier | null;
  theme: Theme;
  currentUser: AuthUser | null;
  pipelineConfig: PipelineConfig;
  messages: Record<string, Message[]>;
  chatRefreshCounter: number;
}

type Action =
  | { type: "SET_WEBSOCKET"; payload: WebSocketManager }
  | { type: "SET_CONVERSATIONS"; payload: Conversation[] }
  | { type: "ADD_CONVERSATION"; payload: Conversation }
  | { type: "RENAME_CONVERSATION"; payload: { chatId: string; name: string } }
  | { type: "REFRESH_CONVERSATIONS" }
  | { type: "TOGGLE_THEME" }
  | { type: "LOGIN"; payload: AuthUser }
  | { type: "LOGOUT" }
  | { type: "SET_MESSAGES"; payload: { chatId: string; messages: Message[] } }
  | { type: "ADD_MESSAGE"; payload: { chatId: string; message: Message, replace?: boolean } }
  | { type: "SET_PIPELINE_CONFIG"; payload: PipelineConfig }

function toggleTheme(state: AppState): AppState {
  const next: Theme = state.theme === "light" ? "dark" : "light";
  localStorage.setItem("theme", next);
  return { ...state, theme: next };
}

function compareMessageDates(a: Message, b: Message): number {
  const dateA = new Date(a.timestamp).getTime()
  const dateB = new Date(b.timestamp).getTime()
  return (dateA === dateB) ? ((a.role === "user") ? -1 : 1) : (dateA - dateB);
}

function compareChatDates(a: Conversation, b: Conversation): number {
  const dateA = new Date(a.timestamp).getTime()
  const dateB = new Date(b.timestamp).getTime()
  return dateB - dateA;
}

function setMessages(state: AppState, chatId: string, messages: Message[]): AppState {
  return {
    ...state, messages: {
      ...state.messages, [chatId]: messages.sort(compareMessageDates)
    }
  };
}

function addMessage(state: AppState, chatId: string, message: Message, replace: boolean = false): AppState {
  if (state.messages[chatId]?.some((msg) => msg.id === message.id)) {
    if (!replace) { return state; }
    return {
      ...state,
      messages: {
        ...state.messages,
        [chatId]: state.messages[chatId].map((msg) =>
          msg.id === message.id ? message : msg
        ).sort(compareMessageDates),
      },
    };
  }
  else {
    return {
      ...state,
      messages: {
        ...state.messages,
        [chatId]: [
          ...(state.messages[chatId] ?? []),
          message,
        ].sort(compareMessageDates),
      },
    };
  }
}

function setConversations(state: AppState, chats: Conversation[]): AppState {
  return {
    ...state, chats: chats.sort(compareChatDates)
  };
}

function renameConversation(state: AppState, payload: { chatId: string; name: string }): AppState {
  const { chatId, name } = payload;
  const newState = {
    ...state,
    chats: state.chats?.map((chat) => (chat.id === chatId ? { ...chat, name } : chat)) ?? [],
  };
  return newState;
}

function addConversation(state: AppState, chat: Conversation): AppState {
  return {
    ...state, chats: [...(state.chats ?? []), chat].sort(compareChatDates)
  };
}

const fetchConversations = async (dispatch: React.Dispatch<Action>) => {
  const conversations: Conversation[] = await (await fetch("/api/chats/")).json();
  dispatch({ type: "SET_CONVERSATIONS", payload: conversations });
};

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case "SET_WEBSOCKET": return { ...state, websocket: action.payload };

    case "SET_CONVERSATIONS": return setConversations(state, action.payload);
    case "ADD_CONVERSATION": return addConversation(state, action.payload);
    case "REFRESH_CONVERSATIONS": return { ...state, chatRefreshCounter: state.chatRefreshCounter + 1 };
    case "RENAME_CONVERSATION": return renameConversation(state, action.payload);

    case "TOGGLE_THEME": return toggleTheme(state);

    case "LOGIN": return { ...state, currentUser: action.payload };
    case "LOGOUT": { authLogout(); return { ...state, currentUser: null }; }

    case "SET_MESSAGES": return setMessages(state, action.payload.chatId, action.payload.messages);
    case "ADD_MESSAGE": return addMessage(state, action.payload.chatId, action.payload.message, action.payload.replace);

    case "SET_PIPELINE_CONFIG": return { ...state, pipelineConfig: action.payload };
    default: return state;
  }
}

export const queryClient = new QueryClient()
export const AppContext = createContext<{ state: AppState; dispatch: React.Dispatch<Action> } | undefined>(undefined);


export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    const root = document.documentElement;
    if (state.theme === "dark") {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
  }, [state.theme]);

  // Conversation fetching effect 
  useEffect(() => {
    if (state.currentUser) fetchConversations(dispatch);
  }, [state.currentUser, state.chatRefreshCounter]);

  // WebSocket effect
  useEffect(() => {
    if (state.currentUser) {
      const wsManager = new WebSocketManager(state.currentUser.id, dispatch);
      dispatch({ type: "SET_WEBSOCKET", payload: wsManager });
      return () => { wsManager.disconnect(); };
    }
  }, [state.currentUser?.id]);

  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}
