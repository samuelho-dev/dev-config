---
title: import util for java
tag: [java]
---

# Test remove statement

```grit
language java

file($body) where {
	$delete_import = `import a.b.Text;`,
	$body <: maybe contains remove_import_statement($delete_import)
}
```

## test remove one import statements when there are more than one import statements

```java
package xx;

import a.b.Text;
import a.b.Form;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

```java
package xx;

import a.b.Form;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

## test remove one import statements when there are only one import statements

```java
package xx;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```

```java
package xx;


public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```

# Test ensure_import_statement

```grit
language java

file($body) where {
	$new_import = `import a.b.Text;`,
	$body <: maybe contains ensure_import_statement($new_import)
}
```

## test `ensure_import_statement` when there already have one

```java
package xx;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```

```java
package xx;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```



## test `ensure_import_statement` when missing import

```java
package xx;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```

```java
package xx;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Text text) {
        this.str = text;
    }
}
```

# Testing `replace_import_statement`

```grit
language java

replace_import_statement(`import a.b.Text;`, `import a.c.Text;`)
```

## test `replace_import_statement` when have

```java
package xx;

import a.b.Text;
import a.b.Form;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

```java
package xx;

import a.c.Text;
import a.b.Form;

import a.c.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```


# Testing `remove_duplicate_import_statements`

```grit
language java

remove_duplicate_import_statements()
```

## test `remove_duplicate_import_statements` when there are some duplicates

```java
package xx;

import a.b.Text;
import a.b.Form;

import a.b.Text;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

```java
package xx;

import a.b.Text;
import a.b.Form;


public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

## test `replace_import_statement` when there are none duplicates

```java
package xx;

import a.b.Text;
import a.b.Form;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

```java
package xx;

import a.b.Text;
import a.b.Form;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

## test `replace_import_statement` when there are none import statements.

```java
package xx;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```

```java
package xx;

public class AClass {
    private Text str;

    private Text getStr() {
        return str;
    }
    private Text setStr(Form form) {
        this.str = form.toText();
    }
}
```
