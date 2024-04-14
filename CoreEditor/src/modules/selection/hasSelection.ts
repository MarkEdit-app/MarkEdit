import selectedRanges from './selectedRanges';

export default function hasSelection() {
  return selectedRanges().some(range => !range.empty);
}
