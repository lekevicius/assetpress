export declare function resolvePath(passedFrom?: string, passedString?: boolean): string;
export declare function escapeShell(cmd: string): string;
export declare function addTrailingSlash(str: string): string;
export declare function removeTrailingSlash(str: string): string;
export declare function cleanMove(from: string, to: string): void;
export declare function dirtyMove(from: string, to: string): void[];
export declare function move(from: string, to: string, clean: boolean): void;
