export const pseudoDocument = `# Heading 1

Hello, World! Open source: [MarkEdit](https://github.com/MarkEdit-app/MarkEdit)

Image link: ![Tux, the Linux mascot](/assets/tux.png), autolink https://markedit.app, or [link references][1].

[1]: http://example.com

Heading level 2
---------------

I just love **bold text**. Italicized text is the *cat's meow*. This text is ***really important***.

> Dorothy followed her through many of the beautiful rooms in her castle.

***

1. First item
2. Second item

- First item
- Second item

\`Inline code\`, and code block:

\`\`\`ts
import fs = require("fs");

class MyClass {
  public static myValue: string;
  constructor(init: string) {
    this.myValue = init;
  }
}

module MyModule {
  export interface MyInterface extends Other {
    myProperty: any;
  }
}

declare magicNumber number;
myArray.forEach(() => { }); // Fat arrow syntax

function $initHighlight(block, cls) {
  try {
    if (cls.search(/\bno-highlight\b/) != -1)
      return process(block, true, 0x0F) +
             \` class="\${cls}"\`;
  } catch (e) {
    /* handle exception */
  }
  for (var i = 0 / 2; i < classes.length; i++) {
    if (checkCondition(classes[i]) === undefined)
      console.log('undefined');
  }

  return (
    <div>
      <web-component>{block}</web-component>
    </div>
  )
}

export  $initHighlight;
\`\`\`

    This is a code segment with four leading spaces

Embedded HTML <demo inline="xml"></demo>

\`\`\`diff
-  color: "#24292e",
+  color: "#24292f",
\`\`\`
`;
