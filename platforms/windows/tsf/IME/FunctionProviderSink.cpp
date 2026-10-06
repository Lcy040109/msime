#include "Private.h"
#include "LingyaoIME.h"
#include "SearchCandidateProvider.h"

//+---------------------------------------------------------------------------
//
// _InitFunctionProviderSink
//
//----------------------------------------------------------------------------

BOOL CLingyaoIME::_InitFunctionProviderSink()
{
    ITfSourceSingle *pSourceSingle = nullptr;
    BOOL ret = FALSE;
    if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfSourceSingle, (void **)&pSourceSingle)))
    {
        IUnknown *punk = nullptr;
        if (SUCCEEDED(QueryInterface(IID_IUnknown, (void **)&punk)))
        {
            if (SUCCEEDED(pSourceSingle->AdviseSingleSink(_tfClientId, IID_ITfFunctionProvider, punk)))
            {
                if (SUCCEEDED(CSearchCandidateProvider::CreateInstance(&_pITfFnSearchCandidateProvider,
                                                                       (ITfTextInputProcessorEx *)this)))
                {
                    ret = TRUE;
                }
            }
            punk->Release();
        }
        pSourceSingle->Release();
    }
    return ret;
}

//+---------------------------------------------------------------------------
//
// _UninitFunctionProviderSink
//
//----------------------------------------------------------------------------

void CLingyaoIME::_UninitFunctionProviderSink()
{
    if (_pITfFnSearchCandidateProvider != nullptr)
    {
        _pITfFnSearchCandidateProvider->Release();
        _pITfFnSearchCandidateProvider = nullptr;
    }

    ITfSourceSingle *pSourceSingle = nullptr;
    if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfSourceSingle, (void **)&pSourceSingle)))
    {
        pSourceSingle->UnadviseSingleSink(_tfClientId, IID_ITfFunctionProvider);
        pSourceSingle->Release();
    }
}
