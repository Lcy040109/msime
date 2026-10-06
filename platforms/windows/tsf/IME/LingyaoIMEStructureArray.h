//////////////////////////////////////////////////////////////////////
//
//  CLingyaoIMELingyaoIMEStructureArray.h
//
//          CLingyaoIMEStructureArray declaration.
//
//////////////////////////////////////////////////////////////////////

#pragma once

#include <vector>

template <class T> class CLingyaoIMEStructureArray
{
    typedef typename std::vector<T> value_type;
    typedef const T &CONST_REF;
    typedef typename value_type CLingyaoIMEArray;
    typedef typename value_type::iterator CLingyaoIMEIter;

  public:
    CLingyaoIMEStructureArray() : _imeVector()
    {
    }

    explicit CLingyaoIMEStructureArray(size_t iCount) : _imeVector(iCount)
    {
    }

    CLingyaoIMEStructureArray(size_t iCount, CONST_REF tVal) : _imeVector(iCount, tVal)
    {
    }

    virtual ~CLingyaoIMEStructureArray()
    {
    }

    inline CONST_REF GetAt(size_t iIndex) const
    {
        assert(iIndex <= _imeVector.size());
        assert(_imeVector.size() > 0);

        return _imeVector[iIndex];
    }

    inline T &GetAt(size_t iIndex)
    {
        assert(iIndex <= _imeVector.size());
        assert(_imeVector.size() > 0);

        return _imeVector[iIndex];
    }

    void RemoveAt(size_t iIndex, size_t iElements)
    {
        assert(iIndex <= _imeVector.size());
        assert(_imeVector.size() > 0);

        CLingyaoIMEIter beginIter = _imeVector.begin() + iIndex;
        CLingyaoIMEIter lastIter = beginIter + iElements - 1;

        _imeVector.erase(beginIter, lastIter);
    }

    size_t Count() const
    {
        return _imeVector.size();
    }

    void Append(const T &tVal)
    {
        _imeVector.push_back(tVal);
    }

    void Clear()
    {
        _imeVector.clear();
    }

  private:
    CLingyaoIMEArray _imeVector; // the actual array of data
    CLingyaoIMEIter _imeIter;
};
