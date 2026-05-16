import { useContext, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Field, FieldGroup } from "@/components/ui/field";
import { AppContext } from "@/AppContext";
import { authLogin, authRegister } from "@/lib/auth";
import { IconDatabase, IconMessages, IconSearch, IconLock, IconArrowLeft } from "@tabler/icons-react";

type Screen = "landing" | "login" | "register";

const features = [
    {
        icon: <IconDatabase size={20} />,
        title: "Document Databases",
        description: "Organise your study materials into named databases. Each database holds the documents that the AI will search through when answering your questions.",
    },
    {
        icon: <IconSearch size={20} />,
        title: "Retrieval-Augmented Generation",
        description: "Every answer is grounded in your documents. The system retrieves the most relevant passages before generating a response, reducing hallucinations.",
    },
    {
        icon: <IconMessages size={20} />,
        title: "Persistent Chat Histories",
        description: "Your conversations are saved per account. Switch between topics freely — the full history is always there when you come back.",
    },
    {
        icon: <IconLock size={20} />,
        title: "Private Accounts",
        description: "Each user has their own account, keeping chat histories and preferences completely separate from other users on the same instance.",
    },
];

export function AuthView() {
    const ctx = useContext(AppContext);
    const [screen, setScreen] = useState<Screen>("landing");
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setError(null);
        setSuccess(null);

        if (screen === "login") {
            const result = await authLogin(username, password);
            if (!result.success) {
                setError(result.error ?? "Login failed.");
            } else {
                ctx?.dispatch({ type: "LOGIN", payload: result.user! });
            }
        } else {
            if (password !== confirmPassword) {
                setError("Passwords do not match.");
                return;
            }
            const result = await authRegister(username, password);
            if (!result.success) {
                setError(result.error ?? "Registration failed.");
            } else {
                setSuccess("Account created! You can now log in.");
                setScreen("login");
                setPassword("");
                setConfirmPassword("");
            }
        }
    }

    function goToScreen(next: Screen) {
        setScreen(next);
        setError(null);
        setSuccess(null);
        setUsername("");
        setPassword("");
        setConfirmPassword("");
    }

    // ── Landing ──────────────────────────────────────────────────────────
    if (screen === "landing") {
        return (
            <div className="flex min-h-screen flex-col bg-background">
                {/* Nav bar */}
                <header className="flex items-center justify-between border-b border-border px-8 py-4">
                    <span className="font-semibold tracking-tight">PF Chatbot</span>
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={() => goToScreen("login")}>
                            Sign in
                        </Button>
                        <Button onClick={() => goToScreen("register")}>
                            Register
                        </Button>
                    </div>
                </header>

                {/* Hero */}
                <section className="flex flex-col items-center justify-center px-6 py-24 text-center">
                    <span className="mb-4 rounded-full border border-border bg-muted px-3 py-1 text-xs font-medium text-muted-foreground uppercase tracking-widest">
                        Retrieval-Augmented Generation
                    </span>
                    <h1 className="max-w-2xl text-4xl font-bold leading-tight tracking-tight sm:text-5xl">
                        Your AI study assistant for Functional Programming
                    </h1>
                    <p className="mt-5 max-w-xl text-base text-muted-foreground leading-relaxed">
                        Upload your lecture notes and papers, then ask questions in plain language.
                        Every answer is grounded in your documents — no hallucinations, no guessing.
                    </p>
                    <div className="mt-8 flex gap-3">
                        <Button size="lg" onClick={() => goToScreen("register")}>
                            Get started — it's free
                        </Button>
                        <Button size="lg" variant="outline" onClick={() => goToScreen("login")}>
                            Sign in
                        </Button>
                    </div>
                </section>

                {/* Feature cards */}
                <section className="mx-auto grid w-full max-w-4xl grid-cols-1 gap-6 px-6 pb-24 sm:grid-cols-2">
                    {features.map((f) => (
                        <div
                            key={f.title}
                            className="rounded-xl border border-border bg-card p-6 flex gap-4"
                        >
                            <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-primary/10 text-primary">
                                {f.icon}
                            </div>
                            <div>
                                <p className="font-semibold text-sm">{f.title}</p>
                                <p className="mt-1 text-sm text-muted-foreground">{f.description}</p>
                            </div>
                        </div>
                    ))}
                </section>

                <footer className="border-t border-border px-8 py-4 text-center text-xs text-muted-foreground/60">
                    PF Chatbot — local accounts, no external authentication required.
                </footer>
            </div>
        );
    }

    // ── Login / Register form ─────────────────────────────────────────────
    return (
        <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4">
            <div className="w-full max-w-sm">
                <button
                    type="button"
                    className="mb-6 flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
                    onClick={() => goToScreen("landing")}
                >
                    <IconArrowLeft size={14} />
                    Back
                </button>

                <h1 className="text-2xl font-semibold tracking-tight">
                    {screen === "login" ? "Sign in" : "Create account"}
                </h1>
                <p className="mt-1 mb-6 text-sm text-muted-foreground">
                    {screen === "login"
                        ? "Enter your credentials to continue."
                        : "Choose a username and password."}
                </p>

                <form onSubmit={handleSubmit}>
                    <FieldGroup>
                        <Field>
                            <Label htmlFor="auth-username">Username</Label>
                            <Input
                                id="auth-username"
                                autoComplete="username"
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                required
                            />
                        </Field>
                        <Field>
                            <Label htmlFor="auth-password">Password</Label>
                            <Input
                                id="auth-password"
                                type="password"
                                autoComplete={screen === "login" ? "current-password" : "new-password"}
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </Field>
                        {screen === "register" && (
                            <Field>
                                <Label htmlFor="auth-confirm">Confirm Password</Label>
                                <Input
                                    id="auth-confirm"
                                    type="password"
                                    autoComplete="new-password"
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    required
                                />
                            </Field>
                        )}
                    </FieldGroup>

                    {error && (
                        <p className="mt-3 text-sm text-destructive">{error}</p>
                    )}
                    {success && (
                        <p className="mt-3 text-sm text-green-600 dark:text-green-400">{success}</p>
                    )}

                    <Button type="submit" className="mt-5 w-full">
                        {screen === "login" ? "Sign in" : "Create account"}
                    </Button>
                </form>

                <p className="mt-5 text-center text-sm text-muted-foreground">
                    {screen === "login" ? (
                        <>
                            Don't have an account?{" "}
                            <button
                                type="button"
                                className="font-medium text-foreground underline underline-offset-4 hover:text-primary"
                                onClick={() => goToScreen("register")}
                            >
                                Register
                            </button>
                        </>
                    ) : (
                        <>
                            Already have an account?{" "}
                            <button
                                type="button"
                                className="font-medium text-foreground underline underline-offset-4 hover:text-primary"
                                onClick={() => goToScreen("login")}
                            >
                                Sign in
                            </button>
                        </>
                    )}
                </p>
            </div>
        </div>
    );
}
