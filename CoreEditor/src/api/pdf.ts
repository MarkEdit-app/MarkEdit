export async function generatePDF(html: string, fileName?: string): Promise<boolean> {
  return window.nativeModules.pdf.generate({ html, fileName });
}
