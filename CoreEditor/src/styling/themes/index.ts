import { EditorTheme } from '../types';

import GitHubLight from './github-light';
import GitHubDark from './github-dark';
import XcodeLight from './xcode-light';
import XcodeDark from './xcode-dark';
import Dracula from './dracula';
import Cobalt from './cobalt';
import WinterIsComingLight from './winter-is-coming-light';
import WinterIsComingDark from './winter-is-coming-dark';
import MinimalLight from './minimal-light';
import MinimalDark from './minimal-dark';
import SynthWave84 from './synthwave84';
import NightOwl from './night-owl';
import RosePineDawn from './rose-pine-dawn';
import RosePine from './rose-pine';

const themes: { [key: string]: (() => EditorTheme) | undefined } = {
  'github-light': GitHubLight,
  'github-dark': GitHubDark,
  'xcode-light': XcodeLight,
  'xcode-dark': XcodeDark,
  'dracula': Dracula,
  'cobalt': Cobalt,
  'winter-is-coming-light': WinterIsComingLight,
  'winter-is-coming-dark': WinterIsComingDark,
  'minimal-light': MinimalLight,
  'minimal-dark': MinimalDark,
  'synthwave84': SynthWave84,
  'night-owl': NightOwl,
  'rose-pine-dawn': RosePineDawn,
  'rose-pine': RosePine,
};

export function loadTheme(name: string): EditorTheme {
  return (themes[name] ?? GitHubLight)();
}

export type { EditorTheme };
