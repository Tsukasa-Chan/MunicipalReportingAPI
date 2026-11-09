/**
 * WordPress User Authentication
 *
 * Provides register, login, logout, and getCurrentUser operations
 * by delegating to the globally injected wvcClient functions.
 * @package WordPress
 */

declare global {
    const wvcClient: {
        register_user: (data: RegisterData) => Promise<RegisterResponse>;
        login_user: (username: string, password: string, remember?: boolean) => Promise<LoginResponse>;
        logout_user: () => Promise<void>;
        get_logged_in_user: () => Promise<CurrentUser>;
        [key: string]: any;
    };
}

// ── Data structures ──────────────────────────────────────────────────────────

/**
 * Data required to register a new WordPress user.
 *
 * Required:
 * - email    — must be a valid email format
 * - password — 8–64 chars, must contain uppercase, lowercase, digit, and special character
 *
 * Optional:
 * - first_name — defaults to ""
 * - last_name  — defaults to ""
 */
export interface RegisterData {
    email: string;
    password: string;
    first_name?: string;
    last_name?: string;
}

/**
 * Successful registration response.
 */
export interface RegisterResponse {
    id: number;
    username: string;
    name: string;
    email: string;
    /** ISO-8601 registration timestamp. */
    registered_date: string;
}

/**
 * Successful login response.
 */
export interface LoginResponse {
    user_display_name: string;
    user_email: string;
    user_nicename: string;
}

/**
 * Current logged-in user profile returned by get_logged_in_user.
 */
export interface CurrentUser {
    id: number;
    username: string;
    email: string;
    display_name: string;
    first_name: string;
    last_name: string;
    /** WordPress roles assigned to this user (e.g. "subscriber"). */
    roles: string[];
    /** Unix timestamp (seconds since epoch) of when the user registered. */
    registered: number;
}

/**
 * Generic error returned when an auth operation fails.
 */
export interface WPError {
    code: string;
    message: string;
}

/**
 * Discriminated-union result type used by every public method.
 *
 * Check `result.success` before accessing `result.data`.
 */
export type AuthResult<T> =
    | { success: true; data: T }
    | { success: false; error: WPError };

// ── WordPressUserAuth class ───────────────────────────────────────────────────

/**
 * WordPress user authentication client.
 *
 * Delegates all operations to the globally injected `wvcClient` functions
 * so authentication state and tokens are managed server-side.
 *
 * @example
 * ```ts
 * const auth = new WordPressUserAuth();
 *
 * const result = await auth.login("alice", "secret");
 * if (result.success) {
 *   console.log(result.data.user_display_name);
 * }
 * ```
 */
export class WordPressUserAuth {
    /**
     * Regex that enforces the WordPress password policy:
     * 8–64 characters, at least one uppercase letter, one lowercase letter,
     * one digit, and one special character.
     *
     * Exposed as a public static so UI components can reference it directly
     * (e.g. as an HTML `pattern` attribute or in a validation library).
     */
    public static readonly PASSWORD_REGEX =
        /^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,64}$/;

    /**
     * Validates a password against the WordPress password policy.
     *
     * @param password - The password string to validate.
     * @returns `true` if the password meets all requirements, `false` otherwise.
     */
    public validatePassword(password: string): boolean {
        return WordPressUserAuth.PASSWORD_REGEX.test(password);
    }

    /**
     * Register a new WordPress user.
     *
     * @param data - Registration payload.
     * @returns Registration response or an WPError.
     */
    public async register(data: RegisterData): Promise<AuthResult<RegisterResponse>> {
        try {
            const response = await wvcClient.register_user(data) as any;
            if (!response.success) {
                return this.toError(response.error);
            }
            return {success: true, data: response.data};
        } catch (err) {
            return this.toError(err);
        }
    }

    /**
     * Authenticate a WordPress user.
     *
     * @param username - WordPress username or email address.
     * @param password - Account password.
     * @param remember - Whether to persist the session. Defaults to false.
     * @returns Login response or a WPError.
     */
    public async login(
        username: string, // accepts either a WordPress username or an email address
        password: string,
        remember: boolean = false
    ): Promise<AuthResult<LoginResponse>> {
        try {
            const response = await wvcClient.login_user(username, password, remember) as any;
            if (!response.success) {
                return this.toError(response.error);
            }
            return {success: true, data: response.data};
        } catch (err) {
            return this.toError(err);
        }
    }

    /**
     * Log out the current user.
     */
    public async logout(): Promise<AuthResult<void>> {
        try {
            const response = await wvcClient.logout_user() as any;
            if (!response.success) {
                return this.toError(response.error);
            }
            return {success: true, data: undefined};
        } catch (err) {
            return this.toError(err);
        }
    }

    /**
     * Fetch the profile of the currently authenticated user.
     *
     * @returns Normalized CurrentUser profile or an WPError.
     */
    public async getCurrentUser(): Promise<AuthResult<CurrentUser>> {
        try {
            const response = await wvcClient.get_logged_in_user() as any;
            if (!response.success) {
                return this.toError(response.error);
            }
            return {success: true, data: response.data};
        } catch (err) {
            return this.toError(err);
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private toError(err: unknown): AuthResult<never> {
        if (err && typeof err === "object" && "code" in err && "message" in err) {
            return {
                success: false,
                error: {
                    code: String((err as any).code),
                    message: String((err as any).message),
                },
            };
        }
        return {
            success: false,
            error: {
                code: "error",
                message: err instanceof Error ? err.message : "An unknown error occurred.",
            },
        };
    }
}