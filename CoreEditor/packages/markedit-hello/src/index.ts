/**
 * A simple greeting function for testing the workspace setup.
 * @param name - The name to greet
 * @returns A greeting message
 */
export function sayHello(name: string = 'World'): string {
  return `Hello, ${name}! Welcome to MarkEdit.`;
}

/**
 * Get the package version.
 * @returns The package version string
 * @note This is a test package, version is hardcoded for simplicity
 */
export function getVersion(): string {
  return '1.0.0';
}
