import os
import fastapi 


def test():
    """
    Blah
    """
    if os.path.exists("Test"):
        pass

    app = fastapi.FastAPI()

    print(app)
