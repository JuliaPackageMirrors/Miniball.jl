module MiniBall
using Cxx

export miniball

const path_to_miniball = joinpath(Pkg.dir("MiniBall"),"deps/downloads/Miniball.hpp")
cxxinclude(path_to_miniball)

cxx"""
#include <iostream>

template <typename N>
N** allocate_c_arr(int length, int width, N * juliaArr) {
    N** output_arr = new N*[length];
    int index = 0;
    for (int i = 0; i < length; i++) {
        N* inner_arr = new N[width];
        for (int j = 1; j < (width + 1); j++) {
            inner_arr[j - 1] = juliaArr[index];
            index += 1;
        }
        output_arr[i] = inner_arr;
    }
    return output_arr;
}

template <typename N>
void free_c_array(int length, N** c_arr) {
    for (int i = 0; i < length; i++)
        free(c_arr[i]);
    free(c_arr);
}

template <typename T>
double calc_mini(int n, int d, T**arr, T *outputArr) {
    double radius;
    typedef T* const* PointIterator; 
    typedef const T* CoordIterator;
    typedef Miniball::Miniball <Miniball::CoordAccessor<PointIterator, CoordIterator> > MB;
    MB mb (n, arr, arr+d);
    const T* center = mb.center(); 
    for(int i=0; i<d; ++i, ++center)
        outputArr[i] = *center;
    radius = mb.squared_radius();
    return radius;
}
"""

allocate_jArr_to_cArr(length, width, juliaArr) = @cxx allocate_c_arr(length, width, juliaArr)
calc_miniball(length, width, arr, outputArr) = @cxx calc_mini(length, width, arr, outputArr)
free_cArr(length, c_arr) = @cxx free_c_array(length, c_arr)

function miniball{T}(arr::Array{T, 2})
    n, d = size(arr)
    output_arr = zeros(d)
    c_arr = allocate_jArr_to_cArr(n, d, pointer(arr'))
    squared_radius = calc_miniball(n, d, c_arr, pointer(output_arr))
    free_cArr(n, c_arr)
    radius = sqrt(squared_radius)
    return output_arr, radius
end

end # module
