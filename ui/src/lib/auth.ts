// NOTE: Client-side stub only. Passwords are base64-encoded for demo purposes.
// A real application must use a backend with proper hashing (bcrypt, argon2, etc.).

interface StoredUser {
    id: string;
    username: string;
    passwordHash: string;
}

export interface AuthUser {
    id: string;
    username: string;
}

function encode(password: string): string {
    return btoa(encodeURIComponent(password));
}

function getUsers(): StoredUser[] {
    try {
        return JSON.parse(localStorage.getItem("auth_users") ?? "[]");
    } catch {
        return [];
    }
}

function saveUsers(users: StoredUser[]): void {
    localStorage.setItem("auth_users", JSON.stringify(users));
}

export function authRegister(
    username: string,
    password: string
): { success: boolean; error?: string } {
    const trimmed = username.trim();
    if (!trimmed) return { success: false, error: "Username is required." };
    if (password.length < 4)
        return { success: false, error: "Password must be at least 4 characters." };
    const users = getUsers();
    if (users.some((u) => u.username.toLowerCase() === trimmed.toLowerCase()))
        return { success: false, error: "Username is already taken." };
    const newUser: StoredUser = {
        id: crypto.randomUUID(),
        username: trimmed,
        passwordHash: encode(password),
    };
    saveUsers([...users, newUser]);
    return { success: true };
}

export function authLogin(
    username: string,
    password: string
): { success: boolean; user?: AuthUser; error?: string } {
    const users = getUsers();
    const user = users.find(
        (u) =>
            u.username.toLowerCase() === username.trim().toLowerCase() &&
            u.passwordHash === encode(password)
    );
    if (!user) return { success: false, error: "Invalid username or password." };
    localStorage.setItem("auth_current_user_id", user.id);
    return { success: true, user: { id: user.id, username: user.username } };
}

export function authLogout(): void {
    localStorage.removeItem("auth_current_user_id");
}

export function authGetCurrentUser(): AuthUser | null {
    const userId = localStorage.getItem("auth_current_user_id");
    if (!userId) return null;
    const users = getUsers();
    const user = users.find((u) => u.id === userId);
    return user ? { id: user.id, username: user.username } : null;
}

export function authChangeUsername(
    userId: string,
    newUsername: string
): { success: boolean; error?: string } {
    const trimmed = newUsername.trim();
    if (!trimmed) return { success: false, error: "Username is required." };
    const users = getUsers();
    if (
        users.some(
            (u) => u.username.toLowerCase() === trimmed.toLowerCase() && u.id !== userId
        )
    )
        return { success: false, error: "Username is already taken." };
    saveUsers(users.map((u) => (u.id === userId ? { ...u, username: trimmed } : u)));
    return { success: true };
}

export function authChangePassword(
    userId: string,
    currentPassword: string,
    newPassword: string
): { success: boolean; error?: string } {
    if (newPassword.length < 4)
        return { success: false, error: "New password must be at least 4 characters." };
    const users = getUsers();
    const user = users.find((u) => u.id === userId);
    if (!user || user.passwordHash !== encode(currentPassword))
        return { success: false, error: "Current password is incorrect." };
    saveUsers(
        users.map((u) => (u.id === userId ? { ...u, passwordHash: encode(newPassword) } : u))
    );
    return { success: true };
}
