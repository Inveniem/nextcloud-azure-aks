"use strict";

const {LocalFilesystem} = require("@inveniem/sftp-ws/lib/fs-local");
const {Path}            = require("@inveniem/sftp-ws/lib/fs-misc");

/**
 * A local filesystem that restricts what sub-paths are visible/accessible.
 */
class FilteredFilesystem extends LocalFilesystem {
  /**
   * Constructor for FilteredFilesystem.
   *
   * @param {string} rootPath
   *   The absolute root path of the filesystem (e.g. "/my/file/system").
   * @param {string[]} allowedPaths
   *   The relative paths under the root file system that are allowed to be
   *   exposed (e.g. "['a', 'b']" means that "/my/file/system/a" and
   *   "/my/file/system/b" but not "/my/file/system/c" should be accessible).
   */
  constructor(rootPath, allowedPaths) {
    super();

    this.rootPath        = Path.create(rootPath, this, 'rootPath').path;
    this.allowedPathList = this.generateFullPaths(rootPath, allowedPaths);
  }

  /**
   * Translate a path to where it should appear on disk.
   *
   * Overrides LocalFilesystem.checkPath() to remap paths that are not on the
   * allow list to a fake "blackhole" path, so that the filesystem acts as if
   * the files/folders do not exist.
   *
   * @param {string} path
   *   The path to translate/check.
   * @param {string} name
   *   The name of the argument of the calling function that is being checked.
   *
   * @returns {string}
   *   The translated and checked path.
   */
  checkPath(path, name) {
    const checkedPath = super.checkPath(path, name);

    if (checkedPath && !this.isPathAllowed(checkedPath)) {
      // A path that should be non-existent.
      return '/blackhole/jail' + checkedPath;
    }
    else {
      return checkedPath;
    }
  }

  /**
   * Opens a directory for listing.
   *
   * Overrides LocalFilesystem.opendir() to filter what files/folders get
   * returned to only those that fall within the allowed paths.
   *
   * @param {string} path
   *   The absolute path of the directory being opened.
   * @param {function} callback
   *   The callback to invoke with the results of opening the directory.
   */
  opendir(path, callback) {
    super.opendir(path, this.buildDirectoryFilterWrapperCallback(callback));
  }

  /**
   * Builds a callback to wrap the callback of an opendir() call.
   *
   * The wrapper callback automatically filters which folders get exposed so
   * only directories on the allow list are returned.
   *
   * @param {function(*, array): void} callback
   *   The callback being wrapped.
   *
   * @returns {function(*, array): void}
   *   The wrapper callback.
   */
  buildDirectoryFilterWrapperCallback(callback) {
    return (err, files) => {
      if (!files['path']) {
        callback(err, files);
      }
      else {
        const dotPaths = ['.', '..'];
        const basePath = files['path'].path;

        const filteredFiles = files.filter((relativePath) => {
          if (dotPaths.includes(relativePath)) {
            return true;
          }
          else {
            const fullPath = basePath + relativePath;

            return this.isPathAllowed(fullPath);
          }
        });

        // BUGBUG: Why does this array have a *string* key inside? This isn't
        // PHP, it's JavaScript.
        filteredFiles['path'] = files['path'];

        callback(err, filteredFiles);
      }
    };
  }

  /**
   * Given a root path and sub-paths, generates a list of absolute paths.
   *
   * For example, if given a root path of "/a/b/c" and sub-paths of "d", "e",
   * and "f", this would return:
   *
   * - "/a/b/c/d"
   * - "/a/b/c/e"
   * - "/a/b/c/f"
   *
   * @param {string} rootPath
   *   The parent path to prepend to each path.
   * @param {string[]} subPaths
   *   The paths nested under the root.
   *
   * @returns {string[]}
   *   Full paths for every sub-path.
   */
  generateFullPaths(rootPath, subPaths) {
    // noinspection UnnecessaryLocalVariableJS
    const allowedPathList =
      subPaths.reduce(
        function (previousValues, currentSubPath) {
          previousValues.push(rootPath + '/' + currentSubPath);

          return previousValues;
        },
        []
      );

    return allowedPathList;
  }

  /**
   * Determines whether a particular path is on the list of allowed paths.
   *
   * @param {string} path
   *   The absolute path to check against the allowed path list.
   *
   * @returns {boolean}
   *   true if the path is allowed to be viewed; or, false, if the path is not
   *   allowed.
   */
  isPathAllowed(path) {
    const strippedPath =
      Path.create(path, this, 'path').removeTrailingSlash().path;

    if (this.rootPath === strippedPath) {
      // We can always browse the root path.
      return true;
    }

    for (const allowedRootPath of this.allowedPathList) {
      if (strippedPath.startsWith(allowedRootPath)) {
        return true;
      }
    }

    return false;
  }
}

module.exports = FilteredFilesystem;
