import Foundation

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise `nil`.
    ///
    /// Use this subscript to safely access elements without risking an index-out-of-range crash:
    /// ```swift
    /// let items = [1, 2, 3]
    /// items[safe: 5] // nil
    /// items[safe: 1] // Optional(2)
    /// ```
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    /// Splits the array into chunks of the given size.
    ///
    /// The last chunk may contain fewer elements if the array length
    /// is not evenly divisible by the chunk size.
    /// ```swift
    /// [1, 2, 3, 4, 5].chunked(into: 2)
    /// // [[1, 2], [3, 4], [5]]
    /// ```
    /// - Parameter size: The maximum number of elements per chunk. Must be greater than 0.
    /// - Returns: An array of arrays, each containing at most `size` elements.
    func chunked(into size: Int) -> [[Element]] {
        precondition(size > 0, "Chunk size must be greater than 0")
        return stride(from: 0, to: count, by: size).map { startIndex in
            Array(self[startIndex ..< Swift.min(startIndex + size, count)])
        }
    }
}
