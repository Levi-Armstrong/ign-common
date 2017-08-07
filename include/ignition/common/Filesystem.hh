/*
 * Copyright 2017 Open Source Robotics Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#ifndef IGNITION_COMMON_FILESYSTEM_HH_
#define IGNITION_COMMON_FILESYSTEM_HH_

#include <memory>
#include <string>

#include <ignition/common/System.hh>

#ifdef _WIN32
// Disable warning C4251 which is triggered by
// std::unique_ptr
#pragma warning(push)
#pragma warning(disable: 4251)
#endif

namespace ignition
{
  namespace common
  {
    /// \brief Determine whether the given path exists on the filesystem.
    /// \param[in] _path  The path to check for existence
    /// \return True if the path exists on the filesystem, false otherwise.
    IGNITION_COMMON_VISIBLE
    bool exists(const std::string &_path);

    /// \brief Determine whether the given path is a directory.
    /// \param[in] _path  The path to check
    /// \return True if given path exists and is a directory, false otherwise.
    IGNITION_COMMON_VISIBLE
    bool isDirectory(const std::string &_path);

    /// \brief Check if the given path is a file.
    /// \param[in] _path Path to a file.
    /// \return True if _path is a file.
    IGNITION_COMMON_VISIBLE
    bool isFile(const std::string &_path);

    /// \brief Create a new directory on the filesystem.  Intermediate
    ///        directories must already exist.
    /// \param[in] _path  The new directory path to create
    /// \return True if directory creation was successful, false otherwise.
    IGNITION_COMMON_VISIBLE
    bool createDirectory(const std::string &_path);

    /// \brief Create directories for the given path
    /// \param[in] _path Path to create directories from
    /// \return true on success
    IGNITION_COMMON_VISIBLE
    bool createDirectories(const std::string &_path);

    // The below is C++ variadic template magic to allow an append
    // method that takes 1-n number of arguments to append together.

    /// \brief Append the preferred path separator character for this platform
    ///        onto the passed-in string.
    /// \param[in] _s  The path to start with.
    /// \return The original path with the platform path separator appended.
    IGNITION_COMMON_VISIBLE
    std::string const separator(std::string const &_s);

    /// \brief Get the absolute path of a provided path.
    /// \param[in] _path Relative or absolute path.
    /// \return Absolute path
    IGNITION_COMMON_VISIBLE
    std::string absPath(const std::string &_path);

    /// \brief Join two strings together to form a path
    /// \param[in] _path1 the left portion of the path
    /// \param[in] _path2 the right portion of the path
    /// \return Joined path
    IGNITION_COMMON_VISIBLE
    std::string joinPaths(const std::string &_path1, const std::string &_path2);

    /// \brief base case for joinPaths(...) below
    inline std::string joinPaths(const std::string &_path)
    {
      return _path;
    }

    /// \brief Append one or more additional path elements to the first
    ///        passed in argument.
    /// \param[in] args  The paths to append together
    /// \return A new string with the paths appended together.
    template<typename... Args>
    inline std::string joinPaths(const std::string &_path1,
                                 const std::string &_path2,
                                 Args const &..._args)
    {
      return joinPaths(joinPaths(_path1, _path2),
                       joinPaths(_args...));
    }

    /// \brief Get the current working directory
    /// \return Name of the current directory
    IGNITION_COMMON_VISIBLE
    std::string cwd();

    /// \brief Given a path, get just the basename portion.
    /// \param[in] _path  The full path.
    /// \return A new string with just the basename portion of the path.
    IGNITION_COMMON_VISIBLE
    std::string basename(const std::string &_path);

    /// \brief Copy a file.
    /// \param[in] _existingFilename Path to an existing file.
    /// \param[in] _newFilename Path of the new file.
    /// \return True on success.
    IGNITION_COMMON_VISIBLE
    bool copyFile(const std::string &_existingFilename,
                  const std::string &_newFilename);

    /// \brief Move a file.
    /// \param[in] _existingFilename Full path to an existing file.
    /// \param[in] _newFilename Full path of the new file.
    /// \return True on success.
    IGNITION_COMMON_VISIBLE
    bool moveFile(const std::string &_existingFilename,
                  const std::string &_newFilename);

    /// \brief Remove an empty directory
    /// \remarks the directory must be empty to be removed
    /// \param[in] _path Path to a directory.
    /// \return True if _path is a directory and was removed.
    IGNITION_COMMON_VISIBLE
    bool removeDirectory(const std::string &_path);

    /// \brief Remove a directory or file.
    /// \param[in] _path Path to a directory or file.
    /// \return True if _path was removed.
    IGNITION_COMMON_VISIBLE
    bool removeDirectoryOrFile(
        const std::string &_path);

    /// \brief Remove a directory or file.
    /// \param[in] _path Path to a directory or file.
    /// \return True if _path was removed.
    IGNITION_COMMON_VISIBLE
    bool removeAll(const std::string &_path);

    /// \internal
    class DirIterPrivate;

    /// \class DirIter Filesystem.hh
    /// \brief A class for iterating over all items in a directory.
    class IGNITION_COMMON_VISIBLE DirIter
    {
      /// \brief Constructor.
      /// \param[in] _in  Directory to iterate over.
      public: explicit DirIter(const std::string &_in);

      /// \brief Constructor for end element.
      public: DirIter();

      /// \brief Dereference operator; returns current directory record.
      /// \return A string representing the entire path of the directory record.
      public: std::string operator*() const;

      /// \brief Pre-increment operator; moves to next directory record.
      /// \return This iterator.
      public: const DirIter& operator++();

      /// \brief Comparison operator to see if this iterator is at the
      ///        same point as another iterator.
      /// \param[in] _other  The other iterator to compare against.
      /// \return true if the iterators are equal, false otherwise.
      public: bool operator!=(const DirIter &_other) const;

      /// \brief Destructor
      public: ~DirIter();

      /// \brief Move to the next directory record, skipping . and .. records.
      private: void Next();

      /// \brief Set the internal variable to the empty string.
      private: void SetInternalEmpty();

      /// \brief Close an open directory handle.
      private: void CloseHandle();

      /// \brief Private data.
      private: std::unique_ptr<DirIterPrivate> dataPtr;
    };
  }
}

#ifdef _WIN32
#pragma warning(pop)
#endif

#endif