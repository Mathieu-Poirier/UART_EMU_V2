#pragma once
#include "stdint.h"

template <typename T, uint32_t N>
class ring_buffer {
private:
    T buffer[N];
    uint32_t head;
    uint32_t tail;
    uint32_t size;

public:
    
    static_assert((N & (N - 1)) == 0, "ring_buffer size N must be a power of two.");

    ring_buffer() noexcept;
    ~ring_buffer() noexcept;

    ring_buffer(const ring_buffer& other) noexcept;
    ring_buffer& operator=(const ring_buffer& other) noexcept;

    ring_buffer(ring_buffer&& other) noexcept;
    ring_buffer& operator=(ring_buffer&& other) noexcept;

    void reset() noexcept;

    [[nodiscard]] bool is_empty() const noexcept;
    [[nodiscard]] bool is_full()  const noexcept;

    bool push(const T& value) noexcept;
    bool pop(T& value) noexcept;
    bool peek(T& value) const noexcept;
};

#include "ring_buffer.tpp"
