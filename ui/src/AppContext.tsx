import { createContext, useEffect, useReducer } from "react";
import type { NamedIdentifier } from "./types";

const initialState: AppState = {
    chats: null,
    databases: null,
    connectionError: false,
    selectedDatabase: null,
};

interface AppState {
    chats: NamedIdentifier[] | null;
    databases: NamedIdentifier[] | null;
    connectionError: boolean;
    selectedDatabase: NamedIdentifier | null;
}

type Action =
    | { type: "SET_CONVERSATIONS"; payload: NamedIdentifier[] }
    | { type: "SET_DATABASES"; payload: NamedIdentifier[] }
    | { type: "CONNECTION_ERROR" }
    | { type: "SELECT_DATABASE"; payload: NamedIdentifier };

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
        default:
            return state;
    }
}

export const AppContext = createContext<{ state: AppState; dispatch: React.Dispatch<Action> } | undefined>(undefined);

export function AppProvider({ children }: { children: React.ReactNode }) {
    const [state, dispatch] = useReducer(reducer, initialState);

    useEffect(() => {
        async function initialLoad() {
            const chatsResp = await fetch("/api/chats/");
            const databasesResp = await fetch("/api/databases/");
            const conversations: NamedIdentifier[] = await chatsResp.json();
            const databases: NamedIdentifier[] = await databasesResp.json();

            dispatch({ type: "SET_CONVERSATIONS", payload: conversations });
            dispatch({ type: "SET_DATABASES", payload: databases });
        };
        initialLoad();
    }, []);

    return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}
