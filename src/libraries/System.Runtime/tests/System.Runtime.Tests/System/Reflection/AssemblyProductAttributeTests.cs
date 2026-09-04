// Licensed to the CodeNet Foundation under one or more agreements.
// The CodeNet Foundation licenses this file to you under the MIT license.

using Xunit;

namespace System.Reflection.Tests
{
    public class AssemblyProductAttributeTests
    {
        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData("product")]
        [InlineData("CodeNet Core")]
        public void Ctor_String(string? product)
        {
            var attribute = new AssemblyProductAttribute(product);
            Assert.Equal(product, attribute.Product);
        }
    }
}
