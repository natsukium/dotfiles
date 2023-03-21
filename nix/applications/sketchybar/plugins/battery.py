import re
import subprocess
from dataclasses import dataclass

from sketchybarrc import IconProps, ItemProps, LabelProps, SketchyBar


@dataclass
class BatteryInfo:
    icon: str
    percentage: int


def getBatteryInfo() -> BatteryInfo:
    result = subprocess.run(["pmset", "-g", "batt"], capture_output=True)
    icon = "" if b"AC Power" in result.stdout else ""
    percentage = re.findall(rb"\d+%", result.stdout)[0].decode("utf-8")

    return BatteryInfo(icon=icon, percentage=percentage)


if __name__ == "__main__":
    info = getBatteryInfo()
    battery = ItemProps(
        icon=IconProps(icon=info.icon), label=LabelProps(label=str(info.percentage))
    )

    sketchybar = SketchyBar().set_item("battery", battery)
    sketchybar.run()
