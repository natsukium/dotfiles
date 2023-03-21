from dataclasses import dataclass

from sketchybarrc import (
    BarProps,
    Event,
    GeometryProps,
    IconProps,
    ItemProps,
    LabelProps,
    ScriptingProps,
    SketchyBar,
    nat,
)


@dataclass
class Nord:
    black = "0xff2e3440"
    white = "0xffeceff4"


def main():
    plugins_dir = "~/.config/sketchybar/plugins/"
    font_familiy = "Liga HackGen Console NF"

    color = Nord()
    bar = BarProps(
        color=color.black,
        height=32,
        blur_radius=nat(30),
        position="top",
        padding_left=nat(10),
        padding_right=nat(10),
        y_offset=10,
        margin=10,
        shadow="true",
        sticky="true",
    )

    default = ItemProps(
        icon=IconProps(
            font=f'"{font_familiy}:Bold:17.0"',
            color=color.white,
            padding_left=4,
            padding_right=4,
        ),
        label=LabelProps(
            font=f'"{font_familiy}:Bold:16.0"',
            color=color.white,
            padding_left=4,
            padding_right=4,
        ),
        geometry=GeometryProps(padding_left=5, padding_right=5),
    )

    battery = ScriptingProps(
        script=plugins_dir + "battery.py",
        update_freq=nat(120),
    )

    clock = ScriptingProps(
        script=plugins_dir + "clock.py",
        update_freq=nat(10),
    )

    sketchybar = SketchyBar()
    sketchybar = (
        sketchybar.set_bar(bar)
        .set_default(default)
        .add_item("clock", "right")
        .set_item("clock", clock)
        .add_item("battery", "right")
        .set_item("battery", battery)
        .set_subscribe("battery", [Event.system_woke, Event.power_source_change])
    )
    print(sketchybar.command)
    sketchybar.run()
    sketchybar.update()


if __name__ == "__main__":
    main()
