import datetime

from sketchybarrc import LabelProps, SketchyBar


def getTimeInfo() -> datetime.datetime:
    return datetime.datetime.now()


if __name__ == "__main__":
    date = getTimeInfo()
    clock = LabelProps(label=date.strftime("%a/%m/%d %H:%M"))

    sketchybar = SketchyBar().set_item("clock", clock)
    sketchybar.run()
