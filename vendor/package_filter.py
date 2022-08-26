import re
import logging
import argparse
from pathlib import Path
from copy import deepcopy as copy


def main(input_file: Path, output_file: Path, vendor_dir: Path) -> None:
    log = logging.getLogger("main")

    package_struct = {
        "name": "",
        "version": "1.0.0",
    }

    # collect vendored packages
    # package_name : {
    #   name: package_name,
    #   version: '1.0.0'
    # }
    required_packages: dict = dict()
    with open(input_file, "r") as f:
        for line in f:
            # psutil==5.9.1; (python_version >= "2.7" and python_full_version < "3.0.0") or (python_full_version >= "3.4.0")
            package_record = line.split(";")[0].split("==")
            package = copy(package_struct)
            package["name"] = package_record[0].strip()
            package["version"] = package_record[1].strip()
            required_packages.update({
                package["name"]: package
            })
            log.debug("Collect required package: %s" % package)
 
    # collect vendored packages
    vendored_packages: list[dict] = list()
    for package_file in vendor_dir.rglob("*"):
        if not package_file.is_file():
            continue

        package = copy(package_struct)
        try:
            # psutil-5.9.1-cp27-cp27m-solaris_2_11_sun4v_32bit.whl
            package_record = package_file.name.split("-")
            package["name"] = package_record[0].strip()
            package["version"] = package_record[1].strip()
        except (ValueError, IndexError):
            log.warning("File '%s' doesn't look like a valid python package" % package_file)
        else:
            vendored_packages.append(package)
            log.info("Found vendored package: %s==%s" % (package["name"], package["version"]))

    # check that all vendored packages are unique
    # it means vendored packages list doesn't contain packages with thw same name but diffident versions
    # check vendor package is present in requirements file
    # check that version of vendored and required package is match 
    vendored_versions: dict[str, str] = dict()
    for current_package in vendored_packages:
        previous_package_version = vendored_versions.get(current_package["name"], None)
        if previous_package_version is not None:
            log.error("Found duplicate of vendored package '%s'" % current_package["name"])
            log.error("With versions %s and %s" % (current_package["version"], previous_package_version))
            log.error("Please get a double check of correctness of your vendored packages")
            exit(1)
        vendored_versions.update({
            current_package["name"]: current_package["version"],
        })
    del vendored_versions

    for vendored_package in vendored_packages:
        package = required_packages.get(vendored_package["name"], None)
        if package is None:
            log.warning("Vendored package %s==%s is not present in requirements file" % (vendored_package["name"], vendored_package["version"]))
        elif package["version"] != vendored_package["version"]:
            log.error("version of vendored package %s==%s doesn't match with version of thw same package from requirements file" % (vendored_package["name"], vendored_package["version"]))
            log.error("Please update package %s from %s to %s" % (vendored_package["name"], package["version"], vendored_package["version"]))
            exit(1)
    

    # create requirements file without vendored packages
    input_requirements = open(input_file, "r")
    output_requirements = open(output_file, "w")
    for line in input_requirements:
        write_line_to_output = True
        for package in vendored_packages:
            name = package["name"]
            version = package["version"]
            if line.startswith(f"{name}=={version}"):
                write_line_to_output = False
                break
        if write_line_to_output:
            output_requirements.write(line)
    input_requirements.close()
    output_requirements.close()


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s: %(message)s "
    )

    parser = argparse.ArgumentParser(description="Small utility for excluding vendored packages from pip-like requirements file")
    parser.add_argument(
        "-i", "--input-file", 
        type=Path,
        metavar="requirements.txt",
        dest="input_file",
    )
    parser.add_argument(
        "-o", "--output-file", 
        type=Path,
        metavar="new-requirements.txt",
        dest="output_file",
    )
    parser.add_argument(
        "--vendor-dir",
        type=Path,
        metavar="/path/to/vendor/arch/",
        dest="vendor_dir",
    )
    args = parser.parse_args()

    main(args.input_file, args.output_file, args.vendor_dir)
