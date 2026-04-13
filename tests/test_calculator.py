import unittest

from calculator import add, divide, subtract


class CalculatorTests(unittest.TestCase):
    def test_add(self) -> None:
        self.assertEqual(add(2, 3), 5)

    def test_subtract(self) -> None:
        self.assertEqual(subtract(7, 4), 3)

    def test_divide(self) -> None:
        self.assertEqual(divide(10, 2), 5.0)

    def test_divide_by_zero_raises(self) -> None:
        with self.assertRaises(ZeroDivisionError):
            divide(3, 0)


if __name__ == "__main__":
    unittest.main()
