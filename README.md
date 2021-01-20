# use-theme

A thin wrapper arround use-package to simplify theme management. I wanted an easy solution to avoid
clutering my config with theme infrastructure code.

## theme style management

You can associate theme to a style by setting the `use-theme-styles` variable:

```
(customize-set-variable 'use-theme-styles '((dark . darker-theme-it-is) (light . a-lighter-one)))
```

You can then switch between themes using `use-theme-switch` or `use-theme-toggle`.

## use-package integration
```
(use-package use-theme :load-path "path/to/use-theme")

(use-theme nord
  :style dark
  :custom-face '(show-paren-match-expression ((t (:background "#434C5E")))))

(use-theme apropospriate
  :name apropospriate-light
  :style light
  :custom-face '(show-paren-match-expression ((t (:background "#F5F5FC")))))

```

This does multiple things. It first does calls the common `use-package` mechanics to install and
load the theme package. It also automatically adds the "-theme" suffix. Most keywords argument are
passed as is to the `use-package` macro.

It then ensures that the `custome-safe-themes` variable is updated with the theme's `sha256`.

It also ensures that the first used theme will be loaded correctly even when running emacs as a
daemon.

The `:style` keyword associate a style to the theme. You can then switch between themes using
`use-theme-switch` or `use-theme-toggle`. It will also ensure that the custom faces are updated when
switching between themes.
