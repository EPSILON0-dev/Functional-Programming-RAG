import { useContext, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Field, FieldGroup } from "@/components/ui/field";
import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { AppContext } from "@/AppContext";
// import { authChangePassword, authChangeUsername } from "@/lib/auth";

interface AccountSettingsDialogProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
}

type Panel = "change-username" | "change-password";

// TODO Improve/make functional

export function AccountSettingsDialog({ open, onOpenChange }: AccountSettingsDialogProps) {
    const ctx = useContext(AppContext);
    const user = ctx?.state.currentUser;

    const [panel, setPanel] = useState<Panel>("change-username");

    // Change username state
    const [newUsername, setNewUsername] = useState("");
    const [usernameError, setUsernameError] = useState<string | null>(null);
    const [usernameSuccess, setUsernameSuccess] = useState(false);

    // Change password state
    const [currentPassword, setCurrentPassword] = useState("");
    const [newPassword, setNewPassword] = useState("");
    const [confirmNewPassword, setConfirmNewPassword] = useState("");
    const [passwordError, setPasswordError] = useState<string | null>(null);
    const [passwordSuccess, setPasswordSuccess] = useState(false);

    function resetState() {
        setNewUsername("");
        setUsernameError(null);
        setUsernameSuccess(false);
        setCurrentPassword("");
        setNewPassword("");
        setConfirmNewPassword("");
        setPasswordError(null);
        setPasswordSuccess(false);
    }

    function handleOpenChange(next: boolean) {
        onOpenChange(next);
        if (!next) resetState();
    }

    function handleChangeUsername(e: React.FormEvent) {
        /*e.preventDefault();
        setUsernameError(null);
        setUsernameSuccess(false);
        if (!user) return;
        const result = authChangeUsername(user.id, newUsername);
        if (!result.success) {
            setUsernameError(result.error ?? "Failed to update username.");
        } else {
            ctx?.dispatch({ type: "UPDATE_USERNAME", payload: newUsername.trim() });
            setUsernameSuccess(true);
            setNewUsername("");
        }*/
    }

    function handleChangePassword(e: React.FormEvent) {
        /*e.preventDefault();
        setPasswordError(null);
        setPasswordSuccess(false);
        if (!user) return;
        if (newPassword !== confirmNewPassword) {
            setPasswordError("New passwords do not match.");
            return;
        }
        const result = authChangePassword(user.id, currentPassword, newPassword);
        if (!result.success) {
            setPasswordError(result.error ?? "Failed to update password.");
        } else {
            setPasswordSuccess(true);
            setCurrentPassword("");
            setNewPassword("");
            setConfirmNewPassword("");
        }*/
    }

    return (
        <Dialog open={open} onOpenChange={handleOpenChange}>
            <DialogContent className="sm:max-w-sm">
                <DialogHeader>
                    <DialogTitle>Account Settings</DialogTitle>
                    <DialogDescription>
                        Signed in as{" "}
                        <span className="font-medium text-foreground">{user?.username}</span>
                    </DialogDescription>
                </DialogHeader>

                {/* Panel tabs */}
                <div className="flex gap-2">
                    <Button
                        size="sm"
                        variant={panel === "change-username" ? "default" : "outline"}
                        onClick={() => setPanel("change-username")}
                    >
                        Username
                    </Button>
                    <Button
                        size="sm"
                        variant={panel === "change-password" ? "default" : "outline"}
                        onClick={() => setPanel("change-password")}
                    >
                        Password
                    </Button>
                </div>

                {panel === "change-username" && (
                    <form onSubmit={handleChangeUsername}>
                        <FieldGroup>
                            <Field>
                                <Label htmlFor="new-username">New Username</Label>
                                <Input
                                    id="new-username"
                                    autoComplete="username"
                                    value={newUsername}
                                    onChange={(e) => setNewUsername(e.target.value)}
                                    required
                                />
                            </Field>
                        </FieldGroup>
                        {usernameError && (
                            <p className="mt-2 text-sm text-destructive">{usernameError}</p>
                        )}
                        {usernameSuccess && (
                            <p className="mt-2 text-sm text-green-600 dark:text-green-400">
                                Username updated successfully.
                            </p>
                        )}
                        <DialogFooter className="mt-4">
                            <DialogClose
                                render={<Button type="button" variant="outline">Close</Button>}
                            />
                            <Button type="submit">Save</Button>
                        </DialogFooter>
                    </form>
                )}

                {panel === "change-password" && (
                    <form onSubmit={handleChangePassword}>
                        <FieldGroup>
                            <Field>
                                <Label htmlFor="current-pw">Current Password</Label>
                                <Input
                                    id="current-pw"
                                    type="password"
                                    autoComplete="current-password"
                                    value={currentPassword}
                                    onChange={(e) => setCurrentPassword(e.target.value)}
                                    required
                                />
                            </Field>
                            <Field>
                                <Label htmlFor="new-pw">New Password</Label>
                                <Input
                                    id="new-pw"
                                    type="password"
                                    autoComplete="new-password"
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                    required
                                />
                            </Field>
                            <Field>
                                <Label htmlFor="confirm-pw">Confirm New Password</Label>
                                <Input
                                    id="confirm-pw"
                                    type="password"
                                    autoComplete="new-password"
                                    value={confirmNewPassword}
                                    onChange={(e) => setConfirmNewPassword(e.target.value)}
                                    required
                                />
                            </Field>
                        </FieldGroup>
                        {passwordError && (
                            <p className="mt-2 text-sm text-destructive">{passwordError}</p>
                        )}
                        {passwordSuccess && (
                            <p className="mt-2 text-sm text-green-600 dark:text-green-400">
                                Password updated successfully.
                            </p>
                        )}
                        <DialogFooter className="mt-4">
                            <DialogClose
                                render={<Button type="button" variant="outline">Close</Button>}
                            />
                            <Button type="submit">Save</Button>
                        </DialogFooter>
                    </form>
                )}
            </DialogContent>
        </Dialog>
    );
}
