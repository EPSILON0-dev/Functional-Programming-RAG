import { useContext, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Field, FieldGroup } from "@/components/ui/field";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { AppContext } from "@/AppContext";
import { useNavigate } from "react-router-dom";

interface AccountSettingsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AccountSettingsDialog({ open, onOpenChange }: AccountSettingsDialogProps) {
  const ctx = useContext(AppContext);
  const user = ctx?.state.currentUser;
  const navigate = useNavigate();

  const [newUsername, setNewUsername] = useState("");
  const [renameError, setRenameError] = useState<string | null>(null);
  const [renameSuccess, setRenameSuccess] = useState(false);

  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordSuccess, setPasswordSuccess] = useState(false);

  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState(false);

  function resetState() {
    setNewUsername("");
    setRenameError(null);
    setRenameSuccess(false);
    setOldPassword("");
    setNewPassword("");
    setConfirmPassword("");
    setPasswordError(null);
    setPasswordSuccess(false);
    setDeleteError(null);
    setDeleteConfirm(false);
  }

  function handleOpenChange(next: boolean) {
    onOpenChange(next);
    if (!next) resetState();
  }

  function handleRename(e: React.FormEvent) {
    e.preventDefault();
    setRenameError(null);
    setRenameSuccess(false);

    fetch("/api/auth/me/username", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: newUsername }),
    })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to rename account");
          });
        }
        return res.json();
      })
      .then((data) => {
        ctx?.dispatch({ type: "LOGIN", payload: { id: data.id, username: data.username } });
        setRenameSuccess(true);
        setNewUsername("");
      })
      .catch((err) => setRenameError(err.message));
  }

  function handleChangePassword(e: React.FormEvent) {
    e.preventDefault();
    setPasswordError(null);
    setPasswordSuccess(false);

    if (newPassword !== confirmPassword) {
      setPasswordError("New passwords do not match");
      return;
    }

    fetch("/api/auth/me/password", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ old_password: oldPassword, new_password: newPassword }),
    })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to change password");
          });
        }
        return res.json();
      })
      .then(() => {
        setPasswordSuccess(true);
        setOldPassword("");
        setNewPassword("");
        setConfirmPassword("");
      })
      .catch((err) => setPasswordError(err.message));
  }

  function handleDeleteAccount() {
    setDeleteError(null);

    fetch("/api/auth/me", { method: "DELETE" })
      .then((res) => {
        if (!res.ok) {
          return res.json().then((data) => {
            throw new Error(data.error || "Failed to delete account");
          });
        }
        return res.json();
      })
      .then(() => {
        ctx?.dispatch({ type: "LOGOUT" });
        navigate("/");
      })
      .catch((err) => setDeleteError(err.message));
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Account Settings</DialogTitle>
          <DialogDescription>
            Signed in as{" "}
            <span className="font-medium text-foreground">{user?.username}</span>
          </DialogDescription>
        </DialogHeader>

        {/* Rename */}
        <form onSubmit={handleRename}>
          <FieldGroup>
            <Field>
              <Label>Change Username</Label>
              <div className="flex gap-2">
                <Input
                  placeholder="New username"
                  autoComplete="off"
                  value={newUsername}
                  onChange={(e) => setNewUsername(e.target.value)}
                  required
                />
                <Button type="submit">Rename</Button>
              </div>
            </Field>
          </FieldGroup>
          {renameError && <p className="mt-1 text-sm text-destructive">{renameError}</p>}
          {renameSuccess && (
            <p className="mt-1 text-sm text-green-600 dark:text-green-400">Username updated.</p>
          )}
        </form>

        <hr className="border-border" />

        {/* Change password */}
        <form onSubmit={handleChangePassword}>
          <FieldGroup>
            <Field>
              <Label>Change Password</Label>
              <Input
                type="password"
                placeholder="Current password"
                autoComplete="current-password"
                value={oldPassword}
                onChange={(e) => setOldPassword(e.target.value)}
                required
              />
              <Input
                type="password"
                placeholder="New password"
                autoComplete="new-password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
              />
              <Input
                type="password"
                placeholder="Confirm new password"
                autoComplete="new-password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
              />
            </Field>
            <Button type="submit" className="mt-2">Change Password</Button>
          </FieldGroup>
          {passwordError && <p className="mt-1 text-sm text-destructive">{passwordError}</p>}
          {passwordSuccess && (
            <p className="mt-1 text-sm text-green-600 dark:text-green-400">Password changed.</p>
          )}
        </form>

        <hr className="border-border" />

        {/* Delete account */}
        <FieldGroup>
          <Label className="text-destructive">Danger Zone</Label>
          {!deleteConfirm ? (
            <Button
              variant="destructive"
              className="mt-1"
              onClick={() => setDeleteConfirm(true)}
            >
              Delete Account
            </Button>
          ) : (
            <div className="flex gap-2 mt-1">
              <Button variant="destructive" onClick={handleDeleteAccount}>
                Yes, delete my account
              </Button>
              <Button variant="outline" onClick={() => setDeleteConfirm(false)}>
                Cancel
              </Button>
            </div>
          )}
          {deleteError && <p className="mt-1 text-sm text-destructive">{deleteError}</p>}
        </FieldGroup>
      </DialogContent>
    </Dialog>
  );
}
