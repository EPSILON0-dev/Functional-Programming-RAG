import { createContext, useEffect, useReducer } from "react";
import type { NamedIdentifier } from "./types";
import { QueryClient } from "@tanstack/react-query";
import { authGetCurrentUser, authLogout, type AuthUser } from "./lib/auth";

type Theme = "light" | "dark";

const storedTheme = (localStorage.getItem("theme") as Theme | null) ?? "light";

const initialState: AppState = {
    chats: null,
    databases: null,
    connectionError: false,
    selectedDatabase: null,
    theme: storedTheme,
    currentUser: await authGetCurrentUser(),
};

interface AppState {
    chats: NamedIdentifier[] | null;
    databases: NamedIdentifier[] | null;
    connectionError: boolean;
    selectedDatabase: NamedIdentifier | null;
    theme: Theme;
    currentUser: AuthUser | null;
}

type Action =
    | { type: "SET_CONVERSATIONS"; payload: NamedIdentifier[] }
    | { type: "SET_DATABASES"; payload: NamedIdentifier[] }
    | { type: "CONNECTION_ERROR" }
    | { type: "SELECT_DATABASE"; payload: NamedIdentifier }
    | { type: "TOGGLE_THEME" }
    | { type: "LOGIN"; payload: AuthUser }
    | { type: "LOGOUT" }
    | { type: "UPDATE_USERNAME"; payload: string };

function reducer(state: AppState, action: Action): AppState {
    switch (action.type) {
        case "SET_CONVERSATIONS":
            return { ...state, chats: action.payload };
        case "SET_DATABASES":
            return { ...state, databases: action.payload };
        case "CONNECTION_ERROR":
            return { ...state, connectionError: true };
        case "SELECT_DATABASE":
            return { ...state, selectedDatabase: action.payload };
        case "TOGGLE_THEME": {
            const next: Theme = state.theme === "light" ? "dark" : "light";
            localStorage.setItem("theme", next);
            return { ...state, theme: next };
        }
        case "LOGIN":
            return { ...state, currentUser: action.payload };
        case "LOGOUT":
            authLogout();
            return { ...state, currentUser: null };
        case "UPDATE_USERNAME":
            return state.currentUser
                ? { ...state, currentUser: { ...state.currentUser, username: action.payload } }
                : state;
        default:
            return state;
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

    useEffect(() => {
        // TODO Run these in parallel
        async function initialLoad() {
            const chatsResp = await fetch("/api/chats/");
            const conversations: NamedIdentifier[] = await chatsResp.json();
            dispatch({ type: "SET_CONVERSATIONS", payload: conversations });

            const databasesResp = await fetch("/api/databases/");
            const databases: NamedIdentifier[] = await databasesResp.json();
            dispatch({ type: "SET_DATABASES", payload: databases });
        };
        initialLoad();
    }, []);

    return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}
