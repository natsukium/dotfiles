import urllib.request

from sketchybarrc import IconProps, ItemProps, LabelProps, SketchyBar

URL = "https://wttr.in?M&format=%c+%t+%w+%p"


if __name__ == "__main__":
    with urllib.request.urlopen(URL) as response:
        body = response.read().decode("utf-8")

    weather = ItemProps(
        icon=IconProps(icon=body.split()[0]),
        label=LabelProps(label=" ".join(body.split()[1:])),
    )

    skechybar = SketchyBar().set_item("weather", weather)
    skechybar.run()
