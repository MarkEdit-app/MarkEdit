export function sleep(milliseconds: number) {
  // eslint-disable-next-line compat/compat
  return new Promise(resolve => {
    setTimeout(resolve, milliseconds);
  });
}
