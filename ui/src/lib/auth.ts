import { toast } from "sonner";

export interface AuthUser {
    id: string;
    username: string;
}

export async function authRegister(username: string, password: string):
    Promise<{ success: boolean; user?: AuthUser; error?: string }> {

    return await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
    }).then(async (response) => {
        if (!response.ok) {
            const errorData = await response.json();
            return { success: false, error: errorData.error ?? "Registration failed." };
        }
        const data = await response.json();
        if (!data || typeof data.username !== "string" || typeof data.id !== "string") {
            return { success: false, error: "Invalid response from server" };
        }
        return { success: true, user: data };
    }).catch((error) => {
        return { success: false, error: error.message ?? "Network error" };
    });
}

export async function authLogin(username: string, password: string):
    Promise<{ success: boolean; user?: AuthUser; error?: string }> {

    return await fetch("/api/auth", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
    }).then(async (response) => {
        if (!response.ok) {
            const errorData = await response.json();
            return { success: false, error: errorData.error ?? "Login failed." };
        }
        const data = await response.json();
        if (!data || typeof data.username !== "string" || typeof data.id !== "string") {
            return { success: false, error: "Invalid response from server" };
        }
        return { success: true, user: data };
    }).catch((error) => {
        return { success: false, error: error.message ?? "Network error" };
    });
}

export async function authGetCurrentUser(): Promise<AuthUser | null> {
    return await fetch("/api/auth/me", {
        method: "GET",
        headers: { "Content-Type": "application/json" },
    }).then(async (response) => {
        const data = await response.json();
        if (!response.ok || !data || typeof data.username !== "string" || typeof data.id !== "string") {
            return null;
        }
        return data;
    }).catch((error) => {
        console.error("Failed to fetch current user:", error);
        return null;
    });
}

export function authLogout(): void {
    fetch("/api/auth/logout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
    }).catch((error) => {
        console.error("Logout failed:", error);
    });
}
