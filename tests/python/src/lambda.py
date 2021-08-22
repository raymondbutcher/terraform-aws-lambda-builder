def handler(event, context):
    import timeprint

    with timeprint:
        import numpy as np

        assert np.array_equal(np.array([1, 2]) + 3, np.array([4, 5]))

    return {"success": True}
