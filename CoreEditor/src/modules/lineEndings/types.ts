export enum LineEndings {
  /**
   * Unspecified, let CodeMirror do the normalization magic.
   */
  Unspecified = 0,
  /**
   * Line Feed, used on macOS and Unix systems.
   */
  LF = 1,
  /**
   * Carriage Return and Line Feed, used on Windows.
   */
  CRLF = 2,
  /**
   * Carriage Return, previously used on Classic Mac OS.
   */
  CR = 3,
}
