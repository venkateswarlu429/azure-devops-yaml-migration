namespace SampleMath;

/// <summary>
/// Small, dependency-free arithmetic used as the packaged sample.
/// Kept deliberately boring: the project is about the pipeline, not
/// the code.
/// </summary>
public static class Calculator
{
    public static double Add(double a, double b) => a + b;

    public static double Subtract(double a, double b) => a - b;

    public static double Multiply(double a, double b) => a * b;

    public static double Divide(double a, double b)
    {
        if (b == 0)
        {
            throw new DivideByZeroException("Divisor must not be zero.");
        }

        return a / b;
    }
}
